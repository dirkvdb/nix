#!/usr/bin/env python3
"""Run on ANOTHER PC, not mini. ICMP/SSH failures do not prove a hard freeze.

Linux/macOS client: Python 3, ssh, ping (ping6 for macOS IPv6).
Remote Linux: timeout, sh, cat, grep, ps, awk, sleep; no root required.
SSH output is read in bounded chunks; partial/very long lines may be split.
"""

import argparse
import ipaddress
import math
import os
from pathlib import Path
import re
import selectors
import shlex
import shutil
import signal
import subprocess
import sys
import threading
import time
from datetime import datetime, timezone


RECONNECT_DELAY = 5
PING_TIMEOUT = 3
HOST = r"[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?"
SIMPLE_TARGET = re.compile(rf"(?:[A-Za-z0-9_][A-Za-z0-9_.-]*@)?({HOST})\Z")
READY = "watch-mini-ready"
PREFLIGHT_ERROR = (
    "SSH preflight failed or timed out; see the SSH log. While mini is healthy, "
    "validate its LAN path with your VPN in the intended state, confirm the "
    "target/--ping-host, and establish trusted host keys and non-interactive "
    "key authentication using native ssh. No full recording started."
)
CHECK = (
    "exec timeout --kill-after=2s 8s sh -c "
    + shlex.quote("command -v sh cat grep ps awk sleep >/dev/null && "
                  "test -r /proc/uptime && printf 'watch-mini-ready\\n'")
)
SAMPLE = r"""while :; do
    printf '\n=== sample ===\nuptime '; cat /proc/uptime
    printf 'boot_id '; cat /proc/sys/kernel/random/boot_id
    for resource in cpu memory io; do
        printf 'pressure_%s\n' "$resource"
        cat "/proc/pressure/$resource"
    done
    grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree|Dirty|Writeback|Slab|SReclaimable|SUnreclaim|PageTables):' /proc/meminfo
    if test -r /sys/fs/cgroup/memory.stat; then
        printf 'cgroup_root_memory.stat\n'
        grep -E '^(anon|file|kernel|kernel_stack|pagetables|slab|sock|shmem|file_dirty|file_writeback|pgscan|pgsteal) ' /sys/fs/cgroup/memory.stat
    fi
    printf 'D-state: stat pid comm wchan\n'
    ps -e -o stat=,pid=,comm=,wchan= | awk '$1 ~ /^D/ {print}'
    sleep INTERVAL
 done
"""


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", help="SSH destination, e.g. dirk@mini")
    parser.add_argument("output_directory", type=Path)
    for option, default, unit in (("hours", 12, "hours"), ("interval", 30, "seconds"),
                                  ("ping-interval", 10, "seconds"),
                                  ("max-mib", 16, "MiB per log; stop at either cap")):
        parser.add_argument("--" + option, type=float, default=default,
                            help=f"positive finite {unit} (default: {default})")
    parser.add_argument("--ping-host", help="DNS name or IP; required for non-simple SSH targets")
    args = parser.parse_args(argv)
    for name, scale in (("hours", 3600), ("interval", 1),
                        ("ping_interval", 1), ("max_mib", 1024 * 1024)):
        value = getattr(args, name) * scale
        if not math.isfinite(value) or value <= 0 or (name == "max_mib" and value < 1):
            parser.error(f"--{name.replace('_', '-')} must be positive, finite and representable")
    if not args.target or args.target.startswith("-") or any(
        c.isspace() or ord(c) < 32 or ord(c) == 127 for c in args.target
    ):
        parser.error("target must be one SSH destination, not options or a command")
    match = SIMPLE_TARGET.fullmatch(args.target)
    if args.ping_host is None:
        if not match:
            parser.error("cannot infer ping host; supply --ping-host DNS_NAME_OR_IP")
        args.ping_host = match[1]
    try:
        ipaddress.ip_address(args.ping_host)
    except ValueError:
        if not re.fullmatch(HOST, args.ping_host):
            parser.error("--ping-host must be a DNS name or IP address, not options")
    return args


def ssh_argv(target, command):
    return ["ssh", "-T", "-n", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5",
            "-o", "ConnectionAttempts=1", "-o", "ServerAliveInterval=5",
            "-o", "ServerAliveCountMax=2", "-o", "StrictHostKeyChecking=yes",
            "-o", "ForwardAgent=no", "-o", "ForwardX11=no",
            "-o", "ClearAllForwardings=yes", "-o", "ControlMaster=no",
            "-o", "ControlPath=none", "--", target, command]


def ping_argv(host, platform):
    if platform == "linux":
        return ["ping", "-n", "-c", "1", "-W", "1", host]
    if platform == "darwin":
        if ":" in host:
            # macOS ping6 does not share ping's millisecond -W option.
            return ["ping6", "-n", "-c", "1", host]
        return ["ping", "-n", "-c", "1", "-W", "1000", host]
    raise ValueError("Only Linux and macOS clients are supported; on Windows use WSL.")


def remote_command(seconds, interval):
    # Round up: timeout's duration 0 would DISABLE the remote lifetime bound.
    return (f"exec timeout --kill-after=2s {max(1, math.ceil(seconds))}s sh -c "
            + shlex.quote(SAMPLE.replace("INTERVAL", str(interval))))


class LogFull(Exception):
    pass


class BoundedLog:
    def __init__(self, path, limit):
        self.file = os.fdopen(os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600),
                              "wb", buffering=0)
        self.remaining = limit

    def write(self, label, text):
        for line in text.splitlines():
            stamp = datetime.now(timezone.utc).isoformat(timespec="milliseconds")
            data = f"{stamp} {label}: {line}\n".encode("utf-8", errors="replace")
            data = data[:self.remaining]
            self.file.write(data)
            self.remaining -= len(data)
            if self.remaining == 0:
                raise LogFull

    def close(self):
        self.file.close()


def spawn(argv):
    return subprocess.Popen(argv, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, start_new_session=True)


def stop_process(process):
    # Kill the group even if the leader already exited: helpers can still hold pipes.
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(process.pid, sig)
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=0.3)
        except subprocess.TimeoutExpired:
            pass
    process.wait(timeout=2)
    process.stdout.close()


def record(args, logs, stop):
    deadline = time.monotonic() + args.hours * 3600
    next_ssh = next_ping = 0
    ready = False
    check_output = b""
    active = {}
    with selectors.DefaultSelector() as selector:
        try:
            while not stop.is_set() and time.monotonic() < deadline:
                now = time.monotonic()
                if "ssh" not in active and now >= next_ssh:
                    command = remote_command(deadline - now, args.interval) if ready else CHECK
                    logs["ssh"].write("status", "connecting" if ready else "preflight SSH check")
                    process = spawn(ssh_argv(args.target, command))
                    active["ssh"] = (process, deadline if ready else min(deadline, now + 12))
                    selector.register(process.stdout, selectors.EVENT_READ, "ssh")
                if ready and "ping" not in active and now >= next_ping:
                    process = spawn(ping_argv(args.ping_host, sys.platform))
                    active["ping"] = (process, min(deadline, now + PING_TIMEOUT))
                    selector.register(process.stdout, selectors.EVENT_READ, "ping")
                    next_ping = now + args.ping_interval
                for key, _ in selector.select(timeout=min(0.2, max(0, deadline - now))):
                    data = os.read(key.fd, 4096)
                    if data:
                        logs[key.data].write(key.data, data.decode("utf-8", errors="replace"))
                        if not ready and key.data == "ssh":
                            check_output = (check_output + data)[-4096:]
                    else:
                        selector.unregister(key.fileobj)
                        key.fileobj.close()
                now = time.monotonic()
                for name, (process, expires) in list(active.items()):
                    timed_out = now >= expires
                    if not timed_out and not (process.stdout.closed and process.poll() is not None):
                        continue
                    if not process.stdout.closed:
                        selector.unregister(process.stdout)
                    stop_process(process)
                    del active[name]
                    logs[name].write("status", f"exit={process.returncode} timeout={timed_out}")
                    if name == "ssh":
                        if not ready:
                            if timed_out or process.returncode != 0 or READY.encode() not in check_output:
                                raise RuntimeError(PREFLIGHT_ERROR)
                            ready = True
                            logs["ssh"].write("status", "SSH healthy; starting recording")
                        next_ssh = now + RECONNECT_DELAY if command != CHECK else now
            if not ready and not stop.is_set():
                raise RuntimeError(PREFLIGHT_ERROR)
            for log in logs.values():
                log.write("status", "signal stop" if stop.is_set() else "duration complete")
        finally:
            for process, _ in active.values():
                stop_process(process)


def main(argv=None):
    args = parse_args(argv)
    stop = threading.Event()
    logs = {}
    handlers = {}
    try:
        ping = ping_argv(args.ping_host, sys.platform)
        for tool in ("ssh", ping[0]):
            if shutil.which(tool) is None:
                raise RuntimeError(f"Required native command not found: {tool}")
        print("WARNING: Run on ANOTHER PC. Connection activity can perturb idle behavior; "
              "use identical instrumentation in both trial arms. Ping/SSH failure is not proof of a freeze.",
              flush=True)
        args.output_directory.mkdir(mode=0o700, parents=True, exist_ok=True)
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
        for name in ("ssh", "ping"):
            path = args.output_directory / f"watch-mini-{stamp}-{name}.log"
            logs[name] = BoundedLog(path, int(args.max_mib * 1024 * 1024))
            print(f"{name}: {path}", flush=True)
        for sig in (signal.SIGINT, signal.SIGTERM):
            handlers[sig] = signal.signal(sig, lambda *_: stop.set())
        record(args, logs, stop)
        return 130 if stop.is_set() else 0
    except LogFull:
        print("Per-log byte cap reached; recorder stopped cleanly.", file=sys.stderr)
        return 0
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"watch-mini: {error}", file=sys.stderr)
        return 1
    finally:
        for log in logs.values():
            log.close()
        for sig, handler in handlers.items():
            signal.signal(sig, handler)


if __name__ == "__main__":
    sys.exit(main())

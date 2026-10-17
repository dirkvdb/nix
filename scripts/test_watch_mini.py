#!/usr/bin/env python3
"""Hermetic tests: child processes are Python snippets, never real SSH or ping."""

import contextlib
import importlib.util
import io
import os
from pathlib import Path
import shlex
import signal
import stat
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest import mock


SPEC = importlib.util.spec_from_file_location(
    "watch_mini", Path(__file__).with_name("watch-mini.py")
)
watch = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(watch)


class ArgumentsTests(unittest.TestCase):
    def parse(self, *extra):
        return watch.parse_args(["dirk@mini.lan", "/unused", *extra])

    def test_defaults_and_simple_targets(self):
        args = self.parse()
        self.assertEqual((args.hours, args.interval, args.ping_interval, args.max_mib),
                         (12, 30, 10, 16))
        for target, host in (("mini", "mini"), ("dirk@mini.lan", "mini.lan"),
                             ("user@192.0.2.1", "192.0.2.1")):
            with self.subTest(target=target):
                self.assertEqual(watch.parse_args([target, "/unused"]).ping_host, host)

    def test_complex_targets_require_explicit_ping_host(self):
        for target in ("ssh://user@mini:2222", "user@[2001:db8::1]"):
            with self.subTest(target=target), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit):
                    watch.parse_args([target, "/unused"])
                args = watch.parse_args([target, "/unused", "--ping-host", "2001:db8::1"])
                self.assertEqual(args.ping_host, "2001:db8::1")

    def test_invalid_values(self):
        for option in ("--hours", "--interval", "--ping-interval", "--max-mib"):
            for value in ("0", "-1", "nan", "inf", "1e309"):
                with self.subTest(option=option, value=value):
                    with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                        self.parse(f"{option}={value}")
        for extra in (("--max-mib", "1e-9"), ("--hours", "1e308"),
                      ("--ping-host=-bad",), ("--ping-host", "host;command")):
            with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                self.parse(*extra)
        for target in ("-oProxyCommand=bad", "user@host command", "host\ncommand"):
            with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                watch.parse_args([target, "/unused", "--ping-host", "mini"])

    def test_help(self):
        with contextlib.redirect_stdout(io.StringIO()) as output:
            with self.assertRaises(SystemExit) as result:
                watch.parse_args(["--help"])
        self.assertEqual(result.exception.code, 0)
        self.assertIn("--ping-host", output.getvalue())

    def test_secure_ssh_argv_and_remote_bound(self):
        argv = watch.ssh_argv("dirk@mini", "remote command")
        self.assertEqual(argv[-3:], ["--", "dirk@mini", "remote command"])
        for option in ("BatchMode=yes", "ConnectTimeout=5", "ServerAliveInterval=5",
                       "ServerAliveCountMax=2", "StrictHostKeyChecking=yes",
                       "ForwardAgent=no", "ClearAllForwardings=yes", "ControlPath=none"):
            self.assertIn(option, argv)
        self.assertIn("-n", argv)
        self.assertIn("-T", argv)
        for seconds, duration in ((43200, "43200s"), (0.00000001, "1s")):
            parts = shlex.split(watch.remote_command(seconds, 30))
            self.assertEqual(parts[:6], ["exec", "timeout", "--kill-after=2s", duration, "sh", "-c"])
            self.assertIn("sleep 30", parts[6])
            self.assertIn("stat=,pid=,comm=,wchan=", parts[6])
            self.assertNotIn("args=", parts[6])

    def test_native_ping_flags(self):
        self.assertEqual(watch.ping_argv("mini", "linux"),
                         ["ping", "-n", "-c", "1", "-W", "1", "mini"])
        self.assertEqual(watch.ping_argv("mini", "darwin"),
                         ["ping", "-n", "-c", "1", "-W", "1000", "mini"])
        self.assertEqual(watch.ping_argv("::1", "darwin"),
                         ["ping6", "-n", "-c", "1", "::1"])
        with self.assertRaisesRegex(ValueError, "WSL"):
            watch.ping_argv("mini", "win32")


class LogTests(unittest.TestCase):
    def test_private_timestamped_logs_and_exact_cap(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "ssh.log"
            log = watch.BoundedLog(path, 170)
            try:
                log.write("ssh", "first\nsecond")
                data = path.read_text()
                self.assertRegex(data, r"(?m)^\d{4}-\d\d-\d\dT.*\+00:00 ssh: first$")
                self.assertIn("ssh: second\n", data)
                with self.assertRaises(watch.LogFull):
                    log.write("ssh", "x" * 4096)
                self.assertEqual(path.stat().st_size, 170)
                with self.assertRaises(watch.LogFull):
                    log.write("ssh", "more")
                self.assertEqual(path.stat().st_size, 170)
                self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)
                with self.assertRaises(FileExistsError):
                    watch.BoundedLog(path, 170)
            finally:
                log.close()


class RecorderTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.args = watch.parse_args(["mini", self.directory.name, "--hours", "0.002"])
        self.stop = threading.Event()
        self.children = []
        self.logs = {}
        for name in ("ssh", "ping"):
            log = watch.BoundedLog(Path(self.directory.name) / f"{name}.log", 16384)
            self.logs[name] = log
            self.addCleanup(log.close)
        self.addCleanup(self.cleanup_children)

    def cleanup_children(self):
        for child in self.children:
            watch.stop_process(child)

    def child(self, code):
        child = subprocess.Popen([sys.executable, "-c", code], stdin=subprocess.DEVNULL,
                                 stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                 start_new_session=True)
        self.children.append(child)
        return child

    def text(self, name):
        return (Path(self.directory.name) / f"{name}.log").read_text()

    def assert_stopped(self):
        for child in self.children:
            self.assertIsNotNone(child.poll())
            self.assertTrue(child.stdout.closed)

    def test_failed_preflight_never_starts_recording(self):
        def spawn(argv):
            self.assertEqual(argv[-1], watch.CHECK)
            return self.child("print('Permission denied'); raise SystemExit(255)")

        with mock.patch.object(watch, "spawn", side_effect=spawn) as start:
            with self.assertRaisesRegex(RuntimeError, "LAN path.*VPN"):
                watch.record(self.args, self.logs, self.stop)
        self.assertEqual(start.call_count, 1)
        self.assertIn("Permission denied", self.text("ssh"))
        self.assertEqual(self.text("ping"), "")
        self.assert_stopped()

    def test_reconnect_and_stream_cleanup_on_signal(self):
        streams = []

        def spawn(argv):
            if argv[0] != "ssh":
                return self.child("print('ping result')")
            if argv[-1] == watch.CHECK:
                return self.child(f"print({watch.READY!r})")
            streams.append(argv[-1])
            code = "print('stream-one')" if len(streams) == 1 else (
                "import time; print('stream-two', flush=True); time.sleep(60)"
            )
            return self.child(code)

        original_write = self.logs["ssh"].write

        def write(label, text):
            original_write(label, text)
            if "stream-two" in text:
                os.kill(os.getpid(), signal.SIGTERM)

        old_handler = signal.signal(signal.SIGTERM, lambda *_: self.stop.set())
        try:
            with mock.patch.object(watch, "spawn", side_effect=spawn), \
                 mock.patch.object(watch, "RECONNECT_DELAY", 0.01), \
                 mock.patch.object(self.logs["ssh"], "write", side_effect=write):
                watch.record(self.args, self.logs, self.stop)
        finally:
            signal.signal(signal.SIGTERM, old_handler)
        self.assertEqual(len(streams), 2)
        self.assertIn("stream-one", self.text("ssh"))
        self.assertIn("signal stop", self.text("ssh"))
        self.assertIn("ping result", self.text("ping"))
        self.assert_stopped()

    def test_newline_free_stream_hits_cap_and_stops_children(self):
        def spawn(argv):
            if argv[-1] == watch.CHECK:
                return self.child(f"print({watch.READY!r})")
            return self.child("import os, time; os.write(1, b'x' * 65536); time.sleep(60)")

        with mock.patch.object(watch, "spawn", side_effect=spawn):
            with self.assertRaises(watch.LogFull):
                watch.record(self.args, self.logs, self.stop)
        self.assertTrue(any((Path(self.directory.name) / f"{name}.log").stat().st_size == 16384
                            for name in self.logs))
        self.assert_stopped()

    def test_deadline_bounds_hung_preflight(self):
        self.args.hours = 0.15 / 3600
        with mock.patch.object(watch, "spawn", side_effect=lambda _: self.child(
            "import time; time.sleep(60)"
        )):
            with self.assertRaisesRegex(RuntimeError, "preflight failed or timed out"):
                watch.record(self.args, self.logs, self.stop)
        self.assert_stopped()

    def test_deadline_and_ping_timeout_stop_hung_children(self):
        self.args.hours = 0.5 / 3600

        def spawn(argv):
            if argv[-1] == watch.CHECK:
                return self.child(f"print({watch.READY!r})")
            return self.child("import time; time.sleep(60)")

        with mock.patch.object(watch, "spawn", side_effect=spawn), \
             mock.patch.object(watch, "PING_TIMEOUT", 0.01):
            watch.record(self.args, self.logs, self.stop)
        self.assertIn("timeout=True", self.text("ping"))
        self.assertIn("duration complete", self.text("ssh"))
        self.assert_stopped()

    def test_spawn_isolates_process_group_and_cleanup_signals_group(self):
        with mock.patch.object(watch.subprocess, "Popen") as popen:
            watch.spawn(["unused"])
        self.assertTrue(popen.call_args.kwargs["start_new_session"])
        self.assertEqual(popen.call_args.kwargs["stdin"], subprocess.DEVNULL)
        child = self.child("import time; time.sleep(60)")
        with mock.patch.object(watch.os, "killpg", wraps=os.killpg) as kill:
            watch.stop_process(child)
        self.assertEqual(kill.call_args_list, [mock.call(child.pid, signal.SIGTERM),
                                              mock.call(child.pid, signal.SIGKILL)])
        self.assert_stopped()

    def test_main_directory_permissions_and_signal_handler_restore(self):
        output = Path(self.directory.name) / "new"
        before = signal.getsignal(signal.SIGTERM)
        with mock.patch.object(watch.shutil, "which", return_value="/unused"), \
             mock.patch.object(watch, "record") as record, \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(watch.main(["mini", str(output)]), 0)
        self.assertEqual(stat.S_IMODE(output.stat().st_mode), 0o700)
        self.assertEqual(len(list(output.iterdir())), 2)
        self.assertEqual(signal.getsignal(signal.SIGTERM), before)
        for log in record.call_args.args[1].values():
            self.assertTrue(log.file.closed)


if __name__ == "__main__":
    unittest.main()

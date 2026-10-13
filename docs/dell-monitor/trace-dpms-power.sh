#!/usr/bin/env bash
# Observe DisplayPort power writes for one idle/wake cycle; never changes DPMS.
set -uo pipefail
umask 077
if [[ $# != 1 || -z ${1:-} ]]; then
    printf 'Usage: %s DIRECTORY\nRun via: nix shell nixpkgs#bpftrace --command bash %s DIRECTORY\n' "$0" "$0" >&2
    exit 2
fi
for cmd in bpftrace sudo timeout tee mkdir mktemp date cat uname; do
    command -v "$cmd" >/dev/null || { printf 'Missing command: %s\n' "$cmd" >&2; exit 1; }
done
bpftrace=$(command -v bpftrace)
timeout_cmd=$(command -v timeout)
mkdir -p -- "$1" && out=$(mktemp -d -- "$1/dpcd-power-XXXXXXXX") || exit 1
printf 'Trace directory: %s\n' "$out"
# Authenticate before starting the time limit. Run this script as your normal user.
sudo -v || exit 1
{
    date --iso-8601=seconds
    "$bpftrace" --version
    uname -a
    printf 'Uptime reference (seconds, includes suspend): '; cat /proc/uptime
} >"$out/context.txt"
printf 'Waiting for probe attachment; then leave the desktop idle. Stops after 20 minutes.\n'
sudo "$timeout_cmd" --signal=INT --kill-after=5s 20m "$bpftrace" -k -e '
kprobe:drm_display_helper:drm_dp_dpcd_write
/arg1 == 0x600/
{
    @start[tid] = (uint64)nsecs(monotonic);
    @aux[tid] = str(((struct drm_dp_aux *)arg0)->name, 64);
    @size[tid] = (uint64)arg3;
    @byte[tid] = (uint64)0;
    if (arg3 > 0 && arg2 != 0) {
        @byte[tid] = (uint64)*kptr((uint8 *)arg2);
    }
    printf("WRITE ns=%llu tid=%u comm=%s aux=\"%s\" size=%llu byte0=0x%02x\n%s\n",
        @start[tid], tid, comm, @aux[tid], @size[tid], @byte[tid], kstack(48));
}

kretprobe:drm_display_helper:drm_dp_dpcd_write
/has_key(@start, tid)/
{
    printf("RESULT start_ns=%llu end_ns=%llu tid=%u aux=\"%s\" size=%llu byte0=0x%02x ret=%lld\n",
        @start[tid], (uint64)nsecs(monotonic), tid,
        @aux[tid], @size[tid], @byte[tid], (int64)retval);
    delete(@start, tid);
    delete(@aux, tid);
    delete(@size, tid);
    delete(@byte, tid);
}

END
{
    clear(@start);
    clear(@aux);
    clear(@size);
    clear(@byte);
}
' 2>&1 | tee "$out/trace.log"
statuses=("${PIPESTATUS[@]}")
printf 'Finished %s; tracer exit=%s, log writer exit=%s\n' \
    "$(date --iso-8601=seconds)" "${statuses[0]}" "${statuses[1]}" >>"$out/context.txt"
printf 'Trace saved: %s/trace.log\n' "$out"
((statuses[1] == 0)) || exit "${statuses[1]}"
# timeout returns 124 after the intentional 20-minute limit.
if ((statuses[0] == 124)); then
    printf 'Reached the 20-minute limit; probes have been detached.\n'
    exit 0
fi
exit "${statuses[0]}"

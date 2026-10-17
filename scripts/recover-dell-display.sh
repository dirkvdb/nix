#!/usr/bin/env bash
# Capture a failed wake before forcing a full output disable/re-enable.
set -Eeuo pipefail
umask 077

usage() {
  cat <<'EOF'
Usage: recover-dell-display.sh [--capture-only] [--monitor DP-3] [--output DIR]

Run as your desktop user, from the affected Hyprland session (or SSH with
HYPRLAND_INSTANCE_SIGNATURE and XDG_RUNTIME_DIR pointing to that session).
Defaults: DP-3; ./result-dell-wake/capture-XXXXXXXX

Captures evidence first, pauses hyprmoncfgd if running, disables the output
for two seconds, then reloads Hyprland to restore the configured monitor rules.
No config files are edited. Reload affects the whole config; windows/workspaces
may move when the output disappears. An exit/signal handler attempts restoration.

--capture-only never changes displays or services. No sudo is requested.
Optional drm_info and readable DRM debugfs files add kernel-level evidence.
Reports may contain identifying information; review before sharing.
EOF
}

monitor=DP-3
output=./result-dell-wake
capture_only=false
while (($#)); do
  case $1 in
    --capture-only) capture_only=true; shift ;;
    --monitor|--output)
      (($# >= 2)) || { usage >&2; exit 2; }
      if [[ $1 == --monitor ]]; then monitor=$2; else output=$2; fi
      shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
[[ $monitor =~ ^[A-Za-z0-9_-]+$ ]] || { echo 'Invalid connector name' >&2; exit 2; }
for cmd in hyprctl jq timeout journalctl systemctl flock; do
  command -v "$cmd" >/dev/null || { echo "Missing command: $cmd" >&2; exit 1; }
done
runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
exec 9>"$runtime/recover-dell-display.lock"
flock -n 9 || { echo 'Another recovery capture is running.' >&2; exit 1; }
mkdir -p -- "$output"
report=$(mktemp -d "$output/capture-XXXXXXXX")
since=$(date --date='20 minutes ago' '+%Y-%m-%d %H:%M:%S')
printf 'Evidence directory: %s\n' "$report"

# Every optional probe is bounded and preserves its error/exit status.
record() {
  local file=$1 status=0
  shift
  timeout 10s "$@" >"$file" 2>&1 || status=$?
  printf '%s\n' "$status" >"$file.exit-status"
}
hypr() { timeout 10s hyprctl "$@"; }
ipc() {
  local reply
  reply=$(hypr "$@") || return
  printf '%s\n' "$reply" >>"$report/recovery.log"
  # hyprctl can report IPC errors in text despite exiting successfully.
  [[ $reply == ok ]] || { printf 'IPC command failed: %s\n' "$reply" >&2; return 1; }
}

snapshot() {
  local phase=$1 dir path file
  dir=$report/$phase
  mkdir -p "$dir"
  date --iso-8601=seconds >"$dir/time.txt"
  record "$dir/monitors.json" hyprctl -j monitors all
  record "$dir/hyprland-version.txt" hyprctl version
  record "$dir/rollinglog.txt" hyprctl rollinglog
  record "$dir/config-errors.txt" hyprctl configerrors
  record "$dir/hyprmoncfg-status.txt" hyprmoncfg status
  record "$dir/kernel-journal.txt" journalctl -b -k --since "$since" --no-pager -o short-iso
  record "$dir/user-journal.txt" journalctl --user -b --since "$since" --no-pager -o short-iso
  record "$dir/drm-info.json" drm_info -j
  {
    uname -a
    cat /proc/cmdline
    cat /sys/module/amdgpu/parameters/dcdebugmask
  } >"$dir/kernel.txt" 2>&1 || true
  {
    for path in /sys/class/drm/card*-*/status; do
      [[ -e $path ]] || continue
      path=${path%/status}
      printf '\n[%s]\n' "$path"
      for file in status enabled dpms link_status; do
        [[ -r $path/$file ]] || continue
        printf '%s: ' "$file"
        cat "$path/$file"
      done
    done
  } >"$dir/connectors.txt" 2>&1
  for path in /sys/kernel/debug/dri/*/state; do
    [[ -r $path ]] || continue
    file=${path%/state}
    file=${file##*/}
    record "$dir/kms-$file.txt" cat "$path"
  done
  # Preserve the full on-disk log, which may contain more than rollinglog.
  if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    path=$runtime/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log
    [[ ! -r $path ]] || record "$dir/hyprland.log" cat "$path"
  fi
  return 0
}

snapshot before
jq -e --arg name "$monitor" '.[] | select(.name == $name and .disabled == false)' \
  "$report/before/monitors.json" >"$report/target-before.json" || {
  echo "Output $monitor is absent/disabled, or Hyprland could not be queried. Evidence saved; no recovery attempted." >&2
  exit 1
}
{
  printf 'Target: %s\n' "$monitor"
  jq '{name, description, width, height, refreshRate, currentFormat, dpmsStatus, disabled}' \
    "$report/target-before.json"
  echo
  echo 'Recent idle/profile events:'
  grep -Ei 'screen-off|display (sleep|wake)|reconciliation|monitor(add|remov)|previewing profile|interactive preview' \
    "$report/before/user-journal.txt" || true
  echo
  echo 'Potential kernel display errors (context is in the full journal):'
  grep -Ei 'amdgpu|drm|displayport|link.train|timeout|gpu.*reset' \
    "$report/before/kernel-journal.txt" || true
  echo
  echo 'Logical DPMS on does not prove the monitor has a picture.'
  echo 'Command success does not establish physical recovery or the root cause.'
  echo 'Probe exit codes are saved alongside each capture; missing permissions/tools are not clean results.'
} >"$report/analysis.txt"
cat "$report/analysis.txt"
$capture_only && exit 0

restart_daemon=false
restore_display=false
cleanup() {
  local status=$?
  trap - EXIT INT TERM HUP
  if $restore_display; then
    echo 'Attempting display restoration after interruption/failure.' >&2
    ipc reload || { echo 'RESTORATION FAILED: run hyprctl reload manually.' >&2; status=1; }
  fi
  if $restart_daemon; then
    timeout 10s systemctl --user start hyprmoncfgd.service || {
      echo 'Could not restart hyprmoncfgd.service.' >&2; status=1;
    }
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

# Refuse to toggle if the configured layout already contains errors.
errors=$(hypr configerrors)
[[ -z $errors || $errors == 'config ok' ]] || {
  echo 'Existing Hyprland config errors; refusing recovery via reload.' >&2; exit 1;
}
ipc eval 'assert(type(hl.monitor) == "function")'
if timeout 10s systemctl --user is-active --quiet hyprmoncfgd.service; then
  restart_daemon=true
  timeout 10s systemctl --user stop hyprmoncfgd.service
fi
printf '%s Disabling %s\n' "$(date --iso-8601=seconds)" "$monitor" >>"$report/recovery.log"
restore_display=true
ipc eval "hl.monitor({ output = \"$monitor\", disabled = true })"
sleep 2
record "$report/disabled-monitors.json" hyprctl -j monitors all
printf '%s Restoring configured layout\n' "$(date --iso-8601=seconds)" >>"$report/recovery.log"
ipc reload
ipc dispatch dpms "on $monitor"
sleep 3
# Keep restoration armed until the output is confirmed logically enabled.
hypr -j monitors all | jq -e --arg name "$monitor" \
  'any(.[]; .name == $name and .disabled == false and .dpmsStatus == true)' >/dev/null
restore_display=false
if $restart_daemon; then
  timeout 10s systemctl --user start hyprmoncfgd.service
  restart_daemon=false
fi
snapshot after
printf '\nRecovery commands completed. Confirm the picture visually. Evidence: %s\n' "$report"

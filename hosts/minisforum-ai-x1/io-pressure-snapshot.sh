#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

once=false
case "$#:${1:-}" in
  0:) ;;
  1:--once) once=true ;;
  *) printf 'Usage: io-pressure-snapshot [--once]\n' >&2; exit 2 ;;
esac

blocked_threads() {
  local pid tid state wchan comm
  # No args/environ or /proc/PID/{cwd,root,fd}: those can expose secrets or touch NFS.
  ps -eLo pid=,lwp=,stat=,wchan:32=,comm= |
    awk '$3 ~ /^D/' |
    while read -r pid tid state wchan comm; do
      printf 'PID=%s TID=%s state=%s comm=%s wchan=%s\n' \
        "$pid" "$tid" "$state" "$comm" "$wchan"
      cat "/proc/$pid/task/$tid/stack" 2>/dev/null ||
        printf '  (stack unavailable: task exited or access denied)\n'
    done
}
export -f blocked_threads

section() {
  local label=$1
  shift
  printf '\n--- %s ---\n' "$label"
  # Kill the whole command group at 10s, including ps and all stack reads together.
  timeout --signal=KILL 10s "$@" ||
    printf '(unavailable or timed out; status %s)\n' "$?"
}

cooldown_until=0
while true; do
  # Reading PSI is the only work on healthy samples; failure stays quiet too.
  # shellcheck disable=SC2016 # These are AWK fields, not shell expansions.
  pressure=$(timeout --signal=KILL 10s awk '
    $1 == "some" {
      split($2, value, "=")
      if (value[2] + 0 >= 5) print value[2]
    }
  ' /proc/pressure/io 2>/dev/null) || pressure=""

  if [[ -n $pressure ]] && (( SECONDS >= cooldown_until )); then
    printf 'I/O pressure snapshot: some avg10=%s%%\n' "$pressure"
    section 'D-state threads and kernel stacks (10s total budget)' \
      "$BASH" -o pipefail -c blocked_threads
    section 'CPU pressure' cat /proc/pressure/cpu
    section 'Memory pressure' cat /proc/pressure/memory
    section 'I/O pressure' cat /proc/pressure/io
    section 'iostat -xz 1 2' iostat -xz 1 2
    section 'pidstat -d -h 1 2' pidstat -d -h 1 2
    section 'vmstat 1 2' vmstat 1 2
    section 'NFS client counters' nfsstat --client
    printf '\nEnd I/O pressure snapshot\n'
    cooldown_until=$((SECONDS + 120))
  fi

  if "$once"; then
    break
  fi
  sleep 30
done

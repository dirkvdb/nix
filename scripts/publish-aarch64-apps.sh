#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -gt 1 ]; then
  echo "Usage: nixcfg-publish-aarch64-apps [cores] (run from the Nix configuration checkout)" >&2
  exit 2
fi

cores="${1:-12}"
case "$cores" in
  ''|*[!0-9]*|0)
    echo "cores must be a positive integer" >&2
    exit 2
    ;;
esac

token_file=/run/secrets/xilo_aarch64_push_token
if [ ! -r "$token_file" ] || [ ! -s "$token_file" ]; then
  echo "ARM cache token is missing or unreadable: deploy xilo_aarch64_push_token first." >&2
  exit 1
fi

# Allow cached ARM wrappers to substitute, without falling back to QEMU builds.
nix build .#aarch64-apps --no-update-lock-file --max-jobs 1 --cores "$cores" \
  --option extra-platforms "" --option always-allow-substitutes true --builders "" \
  --out-link result-aarch64-apps --print-build-logs

XILO_TOKEN="$(cat "$token_file")" xilo push admin/aarch64 ./result-aarch64-apps

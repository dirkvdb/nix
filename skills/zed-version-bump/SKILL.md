# Skill: Bump pinned Zed version safely (with hash refresh)

Use this when updating `modules/home/apps/zed/default.nix` where `zedEditorPinned` is built from GitHub and vendored Cargo deps.

## Why this is needed
Changing `zedPinnedVersion` without refreshing both fixed-output hashes can cause confusing build failures or reuse of stale assumptions.

You must update:
1. `src.hash` (for `fetchFromGitHub`)
2. `cargoDeps.hash` (for `fetchCargoVendor`)

## Procedure
1. Edit `zedPinnedVersion` to the target version (example: `1.2.6`).
2. Temporarily set `src.hash = lib.fakeHash;`.
3. Run `just build` until Nix reports a fixed-output mismatch for the source hash. Copy the reported `got:` hash.
4. Replace `src.hash` with that `got:` value.
5. Temporarily set `cargoDeps.hash = lib.fakeHash;`.
6. Run `just build` until Nix reports a fixed-output mismatch for the vendor hash (often from `*-vendor-staging.drv`). Copy the reported `got:` hash.
7. Replace `cargoDeps.hash` with that `got:` value.
8. Ensure no `fakeHash` remains in the file.
9. Run `just build` for a full verification.

## Notes
- Build can take ~20 minutes.
- If build output is long, tail the end of logs to capture the hash mismatch lines.
- Errors in downstream derivations are expected until both fixed-output hashes are corrected.
- Keep the existing `postBuild` workaround in `fetchCargoVendor` unless there is a clear reason to change it.

## Quick checklist before finishing
- Version updated
- `src.hash` updated from mismatch `got:` value
- `cargoDeps.hash` updated from mismatch `got:` value
- No `fakeHash` left
- `just build` completed successfully

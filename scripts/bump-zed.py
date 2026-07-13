#!/usr/bin/env python3

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

VERSION_PATTERN = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+(?:[.-][0-9A-Za-z.-]+)?$")
HASH_PATTERN = re.compile(r"got:.*?(sha256-[A-Za-z0-9+/]+={0,2})")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Bump pinned Zed and refresh its Nix source and Cargo hashes."
    )
    parser.add_argument("version", help="Zed version, for example 1.10.3")
    args = parser.parse_args()

    if not VERSION_PATTERN.fullmatch(args.version):
        parser.error(f"invalid Zed version: {args.version}")

    return args


def replace_once(text: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.DOTALL)
    if count != 1:
        raise RuntimeError(f"Could not update {label}; the Zed Nix expression may have changed")
    return updated


def set_version(text: str, version: str) -> str:
    return replace_once(
        text,
        r'zedPinnedVersion = "[^"]+";',
        f'zedPinnedVersion = "{version}";',
        "zedPinnedVersion",
    )


def set_hash(text: str, target: str, value: str) -> str:
    expressions = {
        "src": r'(src = unstablePkgs\.fetchFromGitHub \{.*?\n\s*hash = )(?:"[^"]+"|lib\.fakeHash);',
        "cargoDeps": r'(cargoDeps = unstablePkgs\.rustPlatform\.fetchCargoVendor \{.*?\n\s*hash = )(?:"[^"]+"|lib\.fakeHash);',
    }
    return replace_once(text, expressions[target], rf"\g<1>{value};", f"{target}.hash")


def run_build(repo_root: Path, *, expect_hash_for: str | None = None) -> str | None:
    environment = os.environ.copy()
    environment["NO_COLOR"] = "1"

    process = subprocess.Popen(
        ["just", "build"],
        cwd=repo_root,
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        errors="replace",
    )

    found_hash = None
    assert process.stdout is not None
    for line in process.stdout:
        print(line, end="", flush=True)
        if match := HASH_PATTERN.search(line):
            found_hash = match.group(1)

    status = process.wait()

    if expect_hash_for is not None:
        if found_hash is None:
            raise RuntimeError(
                f"Could not find the {expect_hash_for} hash in build output "
                f"(build exit status: {status})"
            )
        return found_hash

    if status != 0:
        raise subprocess.CalledProcessError(status, ["just", "build"])

    return None


def main() -> int:
    args = parse_args()
    repo_root = Path(__file__).resolve().parent.parent
    zed_file = repo_root / "modules/home/apps/zed/default.nix"
    original = zed_file.read_text()

    try:
        config = set_version(original, args.version)
        config = set_hash(config, "src", "lib.fakeHash")
        zed_file.write_text(config)

        print("Building to determine src.hash...", file=sys.stderr)
        src_hash = run_build(repo_root, expect_hash_for="src")
        assert src_hash is not None
        config = set_hash(config, "src", f'"{src_hash}"')
        zed_file.write_text(config)
        print(f"Updated src.hash to {src_hash}")

        config = set_hash(config, "cargoDeps", "lib.fakeHash")
        zed_file.write_text(config)

        print("Building to determine cargoDeps.hash...", file=sys.stderr)
        cargo_hash = run_build(repo_root, expect_hash_for="cargoDeps")
        assert cargo_hash is not None
        config = set_hash(config, "cargoDeps", f'"{cargo_hash}"')

        if "lib.fakeHash" in config:
            raise RuntimeError(f"Refusing to continue: lib.fakeHash remains in {zed_file}")

        zed_file.write_text(config)
        print(f"Updated cargoDeps.hash to {cargo_hash}")

        print("Running final verification build...")
        run_build(repo_root)
    except BaseException:
        zed_file.write_text(original)
        print(f"Zed bump failed; restored {zed_file}", file=sys.stderr)
        raise

    print(f"Zed {args.version} bump completed successfully.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)

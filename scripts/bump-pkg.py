#!/usr/bin/env python3

"""Update a custom package version and refresh its fixed-output hashes."""

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
        description="Bump a custom Nix package and refresh its source hashes."
    )
    parser.add_argument("package", help="custom package name, for example siffra")
    parser.add_argument("version", help="package version, for example 0.3.3")
    args = parser.parse_args()

    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9+._-]*", args.package):
        parser.error(f"invalid package name: {args.package}")
    if not VERSION_PATTERN.fullmatch(args.version):
        parser.error(f"invalid package version: {args.version}")

    return args


def replace_once(text: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.DOTALL)
    if count != 1:
        raise RuntimeError(f"Could not update {label}; the package expression may have changed")
    return updated


def set_version(text: str, version: str) -> str:
    return replace_once(
        text,
        r'(?m)^(\s*version\s*=\s*)"[^"]+";',
        rf'\g<1>"{version}";',
        "version",
    )


def set_source_hash(text: str, value: str) -> str:
    # The first hash following `src =` is the source fixed-output hash. This
    # covers fetchFromGitHub, fetchurl, and the usual `src = let ...` form.
    return replace_once(
        text,
        r"(\bsrc\s*=.*?\bhash\s*=\s*)(?:\"[^\"]+\"|lib\.fakeHash);",
        rf"\g<1>{value};",
        "src.hash",
    )


def set_dependency_hash(text: str, value: str) -> tuple[str, str] | None:
    patterns = (
        (r"(\bcargoHash\s*=\s*)(?:\"[^\"]+\"|lib\.fakeHash);", "cargoHash"),
        (
            r"(\bcargoDeps\s*=.*?\bhash\s*=\s*)(?:\"[^\"]+\"|lib\.fakeHash);",
            "cargoDeps.hash",
        ),
    )
    for pattern, label in patterns:
        updated, count = re.subn(pattern, rf"\g<1>{value};", text, count=1, flags=re.DOTALL)
        if count == 1:
            return updated, label
    return None


def run_build(
    repo_root: Path, package: str, *, expect_hash_for: str | None = None
) -> str | None:
    environment = os.environ.copy()
    environment["NO_COLOR"] = "1"
    expression = (
        "let flake = builtins.getFlake "
        f'"{repo_root}"; '
        "pkgs = import flake.inputs.nixpkgs { "
        "system = builtins.currentSystem; "
        "overlays = [ flake.overlays.default ]; "
        "}; in pkgs."
        f"{package}"
    )
    process = subprocess.Popen(
        ["nix", "build", "--impure", "--expr", expression],
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
        raise subprocess.CalledProcessError(status, ["nix", "build", "--impure", "--expr"])
    return None


def main() -> int:
    args = parse_args()
    repo_root = Path(__file__).resolve().parent.parent
    package_file = repo_root / "pkgs" / args.package / "default.nix"
    if not package_file.is_file():
        raise RuntimeError(f"custom package not found: {package_file.relative_to(repo_root)}")

    original = package_file.read_text()
    try:
        config = set_version(original, args.version)

        config = set_source_hash(config, "lib.fakeHash")
        package_file.write_text(config)
        print("Building to determine src.hash...", file=sys.stderr)
        source_hash = run_build(repo_root, args.package, expect_hash_for="src")
        assert source_hash is not None
        config = set_source_hash(config, f'"{source_hash}"')
        package_file.write_text(config)
        print(f"Updated src.hash to {source_hash}")

        dependency_hash = set_dependency_hash(config, "lib.fakeHash")
        if dependency_hash is not None:
            config, dependency_label = dependency_hash
            package_file.write_text(config)
            print(f"Building to determine {dependency_label}...", file=sys.stderr)
            resolved_hash = run_build(repo_root, args.package, expect_hash_for=dependency_label)
            assert resolved_hash is not None
            updated_dependency_hash = set_dependency_hash(config, f'"{resolved_hash}"')
            if updated_dependency_hash is None:
                raise RuntimeError(
                    f"Could not update {dependency_label}; the package expression may have changed"
                )
            config, _ = updated_dependency_hash
            package_file.write_text(config)
            print(f"Updated {dependency_label} to {resolved_hash}")

        if "lib.fakeHash" in config:
            raise RuntimeError(f"Refusing to continue: lib.fakeHash remains in {package_file}")

        print("Running final verification build...", file=sys.stderr)
        run_build(repo_root, args.package)
    except BaseException:
        package_file.write_text(original)
        print(f"Package bump failed; restored {package_file}", file=sys.stderr)
        raise

    print(f"{args.package} {args.version} bump completed successfully.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)

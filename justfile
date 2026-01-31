# System detection

os_cmd := if os() == "macos" { "darwin" } else { "os" }

# Default recipe - show available commands
default:
    @just --list

# ===== NixOS/Darwin Build Commands =====

# Build the system configuration
build:
    nh {{ os_cmd }} build .

# Test the system configuration
test:
    nh {{ os_cmd }} test .
    nixcfg-reload

# Switch to the new system configuration
switch:
    nh {{ os_cmd }} switch .

# Set configuration to activate on next boot
switch_on_boot:
    nh {{ os_cmd }} boot  .

# Update flake inputs
update:
    nix flake update

# Check all configurations for validity
check:
    nix flake check -L

# Build custom color-lsp package
color-lsp:
    nix-build -E 'with import <nixpkgs> { overlays = [ (final: prev: { color-lsp = prev.callPackage ./pkgs/color-lsp { }; }) ]; }; color-lsp'

# ===== Docker Testing for HPC Home-Manager Config =====

# Test HPC home-manager config in Docker (builds image if needed and launches shell)
docker-hpc-test:
    @bash -euo pipefail -c ' \
        docker_cmd=(docker); \
        if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then \
          docker_cmd=(docker); \
        elif command -v docker >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then \
          echo "Docker requires sudo; using sudo docker." >&2; \
          docker_cmd=(sudo docker); \
        elif command -v docker >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1 && [ -t 0 ] && sudo docker info >/dev/null 2>&1; then \
          echo "Docker requires sudo; using sudo docker." >&2; \
          docker_cmd=(sudo docker); \
        elif command -v podman >/dev/null 2>&1 && podman info >/dev/null 2>&1; then \
          echo "Docker unavailable; using podman." >&2; \
          docker_cmd=(podman); \
        else \
          echo "Container runtime not reachable (docker/podman)." >&2; \
          echo "If you have Docker installed: start it and ensure your user can access /var/run/docker.sock." >&2; \
          exit 1; \
        fi; \
        if ! "${docker_cmd[@]}" image inspect nix-hpc-test >/dev/null 2>&1; then \
          echo "Building Docker image..."; \
          "${docker_cmd[@]}" build -t nix-hpc-test -f hosts/hpc/hpctest.Dockerfile .; \
        fi; \
        run_flags="-i"; \
        if [ -t 0 ] && [ -t 1 ]; then run_flags="-it"; fi; \
        exec "${docker_cmd[@]}" run ${run_flags} --rm --name nix-hpc-test-container nix-hpc-test \
      '

# Clean up Docker test image and containers
docker-hpc-clean:
    @bash -euo pipefail -c ' \
        docker_cmd=(docker); \
        if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then \
          docker_cmd=(docker); \
        elif command -v docker >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then \
          docker_cmd=(sudo docker); \
        elif command -v docker >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1 && [ -t 0 ] && sudo docker info >/dev/null 2>&1; then \
          docker_cmd=(sudo docker); \
        elif command -v podman >/dev/null 2>&1 && podman info >/dev/null 2>&1; then \
          docker_cmd=(podman); \
        else \
          echo "No container runtime reachable (docker/podman); nothing to clean." >&2; \
          exit 0; \
        fi; \
        "${docker_cmd[@]}" rm -f nix-hpc-test-container 2>/dev/null || true; \
        "${docker_cmd[@]}" rmi nix-hpc-test 2>/dev/null || true; \
        echo "Docker HPC test environment cleaned up" \
      '

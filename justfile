# System detection

os_cmd := if os() == "macos" { "darwin" } else { "os" }
hostname := `hostname`
system_config := if hostname == "p220248" { "dell-workstation" } else { hostname }

# Default recipe - show available commands
default:
    @just --list

# ===== NixOS/Darwin Build Commands =====

# Build the system configuration
build:
    nh {{ os_cmd }} build . -H {{ system_config }}

bumpzed version:
    nix shell nixpkgs#python3 -c python3 ./scripts/bump-zed.py "{{ version }}"

# Test the system configuration
test:
    nh {{ os_cmd }} test . -H {{ system_config }}
    nixcfg-reload

# Switch to the new system configuration
switch:
    nh {{ os_cmd }} switch . -H {{ system_config }}

# Set configuration to activate on next boot
switch_on_boot:
    nh {{ os_cmd }} boot . -H {{ system_config }}

# Update flake inputs
update:
    nix flake update

# Check all configurations for validity
check:
    nix flake check -L

# Build a bootable installer ISO with all configs baked in
# Cleanup task available in just 1.54
# [continue]
# iso: && _iso-cleanup
iso:
    @nix shell nixpkgs#openssl -c bash -c 'read -rsp "Encryption password: " PASS; echo; read -rsp "Confirm password: " PASS2; echo; [ "$PASS" = "$PASS2" ] || { echo "Passwords do not match."; exit 1; }; echo "Encrypting files for inclusion in ISO..."; openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:$PASS" -in ~/.local/share/desktop.key -out hosts/installer/desktop.key.enc; openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:$PASS" -in ~/.config/sops/age/keys.txt -out hosts/installer/age-keys.txt.enc; echo "  Encrypted desktop.key and age-keys.txt"'
    git add -f hosts/installer/desktop.key.enc hosts/installer/age-keys.txt.enc
    nix build .#nixosConfigurations.installer.config.system.build.isoImage -L
    git rm -f --cached hosts/installer/desktop.key.enc 2>/dev/null
    git rm -f --cached hosts/installer/age-keys.txt.enc 2>/dev/null
    rm -f hosts/installer/desktop.key.enc hosts/installer/age-keys.txt.enc
    @echo "ISO built:"
    @ls -lh result/iso/*.iso

# _iso-cleanup:
# -git rm -f --cached hosts/installer/desktop.key.enc 2>/dev/null
# rm -f hosts/installer/desktop.key.enc

# Build the installer ISO and burn it to a USB drive
burniso: iso
    nix run nixpkgs#caligula -- burn -z none -s skip result/iso/nixos-*.iso

secrets_edit:
    sops modules/nixos/apps/sops/secrets.yaml

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

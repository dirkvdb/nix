# NixOS Installer ISO

Custom NixOS installer that bakes your flake configuration into a bootable ISO.
After installation, the system is fully configured and ready to use on first boot.

## Building the ISO

```bash
just iso
```

This will:
1. Encrypt `~/.local/share/desktop.key` with a GPG passphrase you provide
2. Bake the encrypted keyfile into the ISO
3. Build the ISO at `result/iso/nixos-*.iso`

## Flashing to USB

```bash
just burniso
```

Builds the ISO (if needed) and launches caligula to pick a USB drive and write it.

Alternatively, flash manually:

```bash
sudo dd if=$(ls result/iso/*.iso) of=/dev/sdX bs=4M status=progress
```

## Installation

1. Boot from the USB drive
2. Log in as `root` (no password required)
3. Run the installer:

```bash
deploy-config
```

The script will guide you through:

- **Step 1** -- Select the target disk from a list of available drives
- **Step 2** -- Optionally enable LUKS disk encryption and set a passphrase
- **Step 3** -- Pick a host configuration (e.g. mini, macbook-pro, dell-workstation)
- **Step 4** -- Set a password (used for both the `dirk` user and `root`)
- **Step 5** -- Review and confirm the settings
- **Steps 6+** -- Automated: partitioning, encryption (if enabled), formatting, mounting,
  hardware detection, config deployment, NixOS installation, password setup, keyfile
  decryption, and file ownership

## Partition layout

The installer creates the following partition layout on the selected disk:

| # | Size | Type | Format | Label   |
|---|------|------|--------|---------|
| 1 | 1G   | EFI  | FAT32  | NIXBOOT |
| 2 | rest | Root | ext4   | NIXROOT |
| 3 | 32G  | Swap | swap   | SWAP    |

When disk encryption is enabled, partitions 2 and 3 are wrapped with LUKS.
The generated `hardware-configuration.nix` will automatically reference the
`/dev/mapper/luks-*` devices and include the LUKS device declarations.

## After installation

Reboot and remove the USB drive. The system boots directly into your configuration.

Your flake source is available at `~/nix`. For future updates:

```bash
cd ~/nix
sudo nixos-rebuild switch --flake .#<hostname>
```

## Included secrets

The KeePassXC keyfile (`~/.local/share/desktop.key`) is encrypted with GPG and
baked into the ISO at build time. During installation, `deploy-config` will
prompt for the decryption passphrase and place the keyfile at
`~/.local/share/desktop.key` on the target system.

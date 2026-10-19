# Manual steps after setting up NixOS
If secure boot is enabled
```bash
sudo sbctl create-keys
```

Register the KeePassXC Git credential helper:
- git-credential-keepassxc configure

# MacBook ARM application cache

Build the MacBook's custom user-space applications without
QEMU or remote builders:

```bash
just publish-macbook-apps
```

# Podman Quadlets

Reusable Quadlet modules live in `modules/quadlets/<name>/default.nix` and are
automatically discovered by `modules/nixos/import.nix`. Each is disabled by
default. Enable them in a host configuration:

```nix
quadlets = {
  homarr.enable = true;
  frigate.enable = true;
  home-assistant.enable = false;
};
```

To add a Quadlet, create `modules/quadlets/<name>/default.nix`, expose
`quadlets.<name>.enable`, and gate its configuration with `lib.mkIf`.
No central import list needs updating. Use `generate-units.nix` to register the
build-time generated service through `systemd.packages`, and declare its
`systemd.units."<service>.service".wantedBy`. This lets NixOS activation manage
changes, removal, and SOPS-triggered restarts rather than relying only on
runtime-generated units.

Enabled Quadlets contribute entries to Homepage's `Quadlets` group when
`services.homepage-dashboard.enable` is enabled. Each module owns its entry via
`services.homepage-dashboard.quadletEntries`; links use the configured hostname
and status checks use localhost. Disabling a Quadlet removes its entry, without
changing whether Homepage itself is enabled.

See the [Frigate module README](modules/quadlets/frigate/README.md) for
configuration, GPU acceleration, and migration instructions.

Home Assistant remains disabled on mediastation. Enabling it opens TCP port
`8123` and uses the original host-networked, privileged container definition.
Homarr retains its existing port `8083`, data directory, and encryption key.
Container images are downloaded on first service startup, not during the Nix
system build.

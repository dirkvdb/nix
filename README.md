# Manual steps after setting up NixOS
If secure boot is enabled
```bash
sudo sbctl create-keys
```

Register the KeePassXC Git credential helper:
- git-credential-keepassxc configure

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

## Frigate migration

Frigate runs the pinned `ghcr.io/blakeblackshear/frigate:0.17.2` image as
`frigate.service`. The authenticated HTTP UI remains at port `8085`; the
unauthenticated API and go2rtc ports are not exposed. TLS remains disabled, as
in the previous configuration. The container's bundled go2rtc replaces the
standalone service.

Camera and recording settings live in `modules/quadlets/frigate/settings.nix`.
SOPS supplies the MQTT and camera credentials, notification email, and admin
password. Runtime configuration is regenerated from Nix on every restart, so
UI configuration edits are not persistent.

The existing `/var/lib/frigate` directory is mounted in place for both the
database and media. Before container startup, known native media paths in the
database are normalized to `/media/frigate/` so existing previews, recordings,
and exports remain accessible. This is transactional and creates a mode-`0600`
SQLite backup at `/var/lib/frigate/frigate.db.pre-quadlet-<unique>.backup` before
changing any paths; its location is logged to the service journal. The original
absolute path remains mounted as well for legacy paths.

Before first activation, stop the native Frigate service and back up
`/var/lib/frigate` (including the database and its SQLite journal files). Never
run native Frigate and the Quadlet against the database simultaneously. Normal
Frigate schema migrations may occur; container-created files may be root-owned.
For a native-service rollback, stop the Quadlet and restore the pre-migration
database backup and suitable native ownership rather than sharing a live
container database.

Home Assistant remains disabled on mediastation. Enabling it opens TCP port
`8123` and uses the original host-networked, privileged container definition.
Homarr retains its existing port `8083`, data directory, and encryption key.
Container images are downloaded on first service startup, not during the Nix
system build.

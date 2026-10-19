{
  pkgs,
  podman,
  name,
  source ? null,
  text ? null,
  serviceName ? name,
}:
pkgs.runCommand "${name}-quadlet-units"
  {
    QUADLET_UNIT_DIRS =
      if source == null then
        pkgs.writeTextDir "${name}.container" text
      else
        pkgs.runCommand "${name}-quadlet-source" { } ''
          mkdir -p "$out"
          ln -s ${source} "$out/${name}.container"
        '';
    PODMAN = "${podman}/bin/podman";
    preferLocalBuild = true;
  }
  ''
    mkdir -p "$out/lib/systemd/system"
    ${podman}/libexec/podman/quadlet --no-kmsg-log "$out/lib/systemd/system"
    test -s "$out/lib/systemd/system/${serviceName}.service"
  ''

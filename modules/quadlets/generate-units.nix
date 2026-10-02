{
  pkgs,
  podman,
  name,
  text,
  serviceName ? name,
}:
pkgs.runCommand "${name}-quadlet-units"
  {
    QUADLET_UNIT_DIRS = pkgs.writeTextDir "${name}.container" text;
    PODMAN = "${podman}/bin/podman";
    preferLocalBuild = true;
  }
  ''
    mkdir -p "$out/lib/systemd/system"
    ${podman}/libexec/podman/quadlet --no-kmsg-log "$out/lib/systemd/system"
    test -s "$out/lib/systemd/system/${serviceName}.service"
  ''

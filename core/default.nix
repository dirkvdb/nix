{
  lib,
  ...
}:
# Core module aggregator (simplified).
# Unconditionally imports all .nix files in this directory and, on Linux, all in ./linux.
# Enable flags remain defined but do not gate imports.
let
  readNixFiles =
    dir:
    let
      entries = builtins.readDir dir;
      names = lib.attrNames entries;
    in
    lib.filter (n: lib.hasSuffix ".nix" n && n != "default.nix") names;

  coreFileNames = readNixFiles ./.;
  linuxFileNames = readNixFiles ./linux;

  coreImports = map (fname: ./. + "/${fname}") coreFileNames;
  linuxImports = map (fname: ./linux + "/${fname}") linuxFileNames;
in
{
  options.nixCfg = {
    applications.enable = lib.mkEnableOption "Applications module";
    configuration.enable = lib.mkEnableOption "Base system configuration";
    applications.gui = lib.mkEnableOption "Additional GUI applications";
  };

  imports = coreImports ++ linuxImports;
}

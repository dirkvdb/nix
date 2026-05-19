{
  lib,
  config,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.system.dev;
in
{
  options.local.system.dev = {
    enable = lib.mkEnableOption "Developer-focused tooling (devenv, just, lazygit, etc.)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      [
        just
        lazygit
        serie
        binsider
        nixd
        unstablePkgs.devenv
        unstablePkgs.pixi
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        unstablePkgs.codex
      ];
  };
}

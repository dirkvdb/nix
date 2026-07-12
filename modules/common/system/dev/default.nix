{
  lib,
  config,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.system.dev;
  inherit (config.local) user;
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
        serie
        binsider
        nixd
        unstablePkgs.devenv
        unstablePkgs.pixi
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        unstablePkgs.codex
        unstablePkgs.github-copilot-cli
      ];

    home-manager.users.${user.name} = {
      # TODO: Enable this when it hits stable home manager
      # programs.devenv = {
      #   enable = true;
      #   package = unstablePkgs.devenv;
      # };

      programs.lazygit = {
        enable = true;
      };

      # Pixi configuration
      xdg.configFile."pixi/config.toml".text = ''
        [shell]
        change-ps1 = false
      '';
    };
  };
}

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
        unstablePkgs.sccache
        unstablePkgs.devenv
        unstablePkgs.pixi
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        unstablePkgs.codex
        unstablePkgs.ccusage
        unstablePkgs.github-copilot-cli
      ];

    home-manager.users.${user.name} = {
      programs.devenv = {
        enable = true;
        package = unstablePkgs.devenv;
      };

      programs.lazygit = {
        enable = true;
      };

      # Use sccache to cache Rust builds
      home.file.".cargo/config.toml".text = ''
        [build]
        rustc-wrapper = "${unstablePkgs.sccache}/bin/sccache"
      '';

      # Pixi configuration
      xdg.configFile."pixi/config.toml".text = ''
        [shell]
        change-ps1 = false
      '';
    };
  };
}

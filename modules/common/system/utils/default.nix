{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.utils;
  hasDesktop = config.local.desktop.enable or false;
  dev = with pkgs; [
    devenv
    mise
    just
    pixi
    lazygit
  ];
  sysadmin = with pkgs; [
    bind
    killall
  ];
in
{
  options.local.system.utils = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable installation of common system utilities.";
    };

    dev = lib.mkEnableOption "Developer-focused tooling (e.g., mise, just)";
    sysadmin = lib.mkEnableOption "Sysadmin-focused tooling (bind, killall, usbutils on Linux)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      [
        fd
        jq # needed by some scripts
        curl
        file
        fzf
        micro
        rsync
        ripgrep
        zip
        unzip
        wget
        p7zip
      ]
      ++ lib.optionals cfg.dev dev
      ++ lib.optionals cfg.sysadmin sysadmin
      ++ lib.optionals hasDesktop [
        sublime-merge
      ];

    programs.direnv = {
      enable = cfg.dev;
    };
  };

}

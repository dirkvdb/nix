{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.utils;
  hasDesktop = config.local.desktop.enable or false;
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

    sysadmin = lib.mkEnableOption "Sysadmin-focused tooling (bind, killall, usbutils on Linux)";

    dev = lib.mkEnableOption "Developer-focused tooling (devenv, just, lazygit, etc.)";
  };

  config = lib.mkIf cfg.enable {
    local.system.dev.enable = cfg.dev;
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
      ++ lib.optionals cfg.sysadmin sysadmin
      ++ lib.optionals hasDesktop [
        sublime-merge
        pinta # image editor
      ];
  };

}

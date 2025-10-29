{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.utils;
  dev = with pkgs; [
    direnv
    mise
    just
    lazygit
  ];
  sysadmin =
    with pkgs;
    [
      bind
      killall
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      usbutils
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
        cpufrequtils
        file
        fzf
        ripgrep
        unzip
        wget
        p7zip
      ]
      ++ lib.optionals cfg.dev dev
      ++ lib.optionals cfg.sysadmin sysadmin
      ++ lib.optionals config.local.desktop.enable [
        sqlitebrowser
        sublime-merge
      ];
  };
}

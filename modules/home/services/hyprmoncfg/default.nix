{
  lib,
  pkgs,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.services.hyprmoncfg;
  mkUserHome = mkHome user.name;
in
{
  options.local.services.hyprmoncfg = {
    enable = lib.mkEnableOption "hyprmoncfg monitor profile daemon";
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    home.packages = [ pkgs.hyprmoncfg ];

    xdg.configFile."systemd/user/hyprmoncfgd.service".source =
      "${pkgs.hyprmoncfg}/share/systemd/user/hyprmoncfgd.service";
    xdg.configFile."systemd/user/default.target.wants/hyprmoncfgd.service".source =
      "${pkgs.hyprmoncfg}/share/systemd/user/hyprmoncfgd.service";

    xdg.configFile."hyprmoncfg/profiles" = {
      source = ./profiles;
      recursive = true;
    };
  });
}

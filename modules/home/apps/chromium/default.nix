{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable;
in
{
  home-manager.users.${user.name} = lib.mkIf (isLinux && isDesktop) {
    # we always install chromium when on desktop linux because it is used as web app host
    programs.chromium = {
      enable = true;
      package = pkgs.chromium;

      extensions = [
        "oboonakemofpalcgghocfoadofidjkkk" # keepassxc
      ];
    };
  };
}

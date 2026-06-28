{
  config,
  lib,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable or false;
  isHeadless = config.local.headless or false;
  isHyprlandEnabled = config.local.desktop.hyprland.enable or false;
  isX86 = pkgs.stdenv.isx86_64;
  vpnjumphostEnabled = config.local.services.vpnjumphost.enable;
  officeworkEnabled = config.local.services.officework.enable;
  mkUserHome = mkHome user.name;

  musicCmd =
    if isX86 then
      ''launch_or_focus("spotify")''
    else
      ''launch_or_focus("Spotify", [[nixcfg-launch-webapp "https://open.spotify.com"]])'';
in
{
  config = lib.mkIf (isLinux && isDesktop && !isHeadless && isHyprlandEnabled) (mkUserHome {
    wayland.windowManager.hyprland.configType = "lua";

    # Nix-conditional keybindings (music command depends on architecture,
    # VPN jumphost and officework are optional services).
    wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
      hl.bind("SUPER + SHIFT + M", ${musicCmd}, { description = "Music" })
      ${lib.optionalString vpnjumphostEnabled ''hl.bind("SUPER + ALT + J", hl.dsp.exec_cmd("nixcfg-toggle-vpn-jumphost"), { description = "Toggle VPN jumphost" })''}
      ${lib.optionalString officeworkEnabled ''hl.bind("SUPER + ALT + O", hl.dsp.exec_cmd("nixcfg-toggle-officework"), { description = "Toggle officework services" })''}
    '';
  });
}

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

  vpnjumphostEnabled = config.local.services.vpnjumphost.enable;
  officeworkEnabled = config.local.services.officework.enable;
  voxtypeEnabled = config.local.apps.voxtype.enable or false;
  mkUserHome = mkHome user.name;

  musicCmd = "nixcfg-launch-or-focus spotifast";
in
{
  config = lib.mkIf (isLinux && isDesktop && !isHeadless && isHyprlandEnabled) (mkUserHome {
    wayland.windowManager.hyprland.configType = "lua";

    # Music shortcut and Nix-conditional keybindings for optional services.
    wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
      hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd(${
        lib.generators.toLua { } musicCmd
      }), { description = "Music" })
      ${lib.optionalString vpnjumphostEnabled ''hl.bind("SUPER + ALT + J", hl.dsp.exec_cmd("nixcfg-toggle-vpn-jumphost"), { description = "Toggle VPN jumphost" })''}
      ${lib.optionalString officeworkEnabled ''hl.bind("SUPER + ALT + O", hl.dsp.exec_cmd("nixcfg-toggle-officework"), { description = "Toggle officework services" })''}
      ${lib.optionalString voxtypeEnabled ''hl.bind("SUPER + SHIFT + X", hl.dsp.exec_cmd("voxtype record toggle"), { description = "Toggle dictation" })''}
    '';
  });
}

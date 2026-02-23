{
  lib,
  config,
  inputs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.lan-mouse;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.lan-mouse = {
    enable = lib.mkEnableOption "Lan-mouse software kvm";
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    imports = [ inputs.lan-mouse.homeManagerModules.default ];

    programs.lan-mouse = {
      enable = true;
      # settings = {
      #   # The port the lan-mouse server listens on
      #   port = 12345;
      # };
    };
  });
}

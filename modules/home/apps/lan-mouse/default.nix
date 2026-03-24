{
  lib,
  config,
  options,
  inputs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.lan-mouse;
  isHeadless = config.local.headless or false;
  hasNestedHomeManager = lib.hasAttrByPath [ "home-manager" "users" ] options; # hack can be removed one the latest release is in home manager
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.lan-mouse = {
    enable = lib.mkEnableOption "Lan-mouse software kvm";
  };

  config =
    if hasNestedHomeManager then
      lib.mkIf (cfg.enable && !isHeadless) (mkUserHome {
        imports = [ inputs.lan-mouse.homeManagerModules.default ];

        programs.lan-mouse = {
          enable = true;
          # settings = {
          #   # The port the lan-mouse server listens on
          #   port = 12345;
          # };
        };
      })
    else
      { };
}

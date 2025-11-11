{
  lib,
  config,
  inputs,
  system,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.user.home-manager;
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
  ];

  config = lib.mkIf cfg.enable {
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      extraSpecialArgs = {
        inherit
          inputs
          system
          user
          ;
        zen-browser = inputs.zen-browser;
      };
      sharedModules = [
        inputs.zen-browser.homeModules.default
      ];
      users.${user.name}.imports = [ ./home.nix ];
    };
  };
}

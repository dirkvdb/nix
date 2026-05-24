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
    inputs.home-manager.nixosModules.home-manager
  ];

  config = lib.mkIf cfg.enable {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      extraSpecialArgs = {
        inherit
          inputs
          system
          user
          ;
      };
      sharedModules = [
        inputs.zen-browser.homeModules.default
        inputs.nvf.homeManagerModules.default
        inputs.walker.homeManagerModules.default
      ];
      users.${user.name}.imports = [
        ./home.nix
      ];
    };
  };
}

{
  lib,
  config,
  inputs,
  system,
  userConfig,
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
          userConfig
          user
          ;
        elephant = inputs.elephant;
        walker = inputs.walker;
        zen-browser = inputs.zen-browser;
      };
      users.${user.name}.imports = [
        ./home.nix
      ];
    };
  };
}

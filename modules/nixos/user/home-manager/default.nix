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
  isNoctaliaEnabled = config.local.desktop.noctalia.enable or false;
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
          isNoctaliaEnabled
          ;
      };
      sharedModules = [
        inputs.zen-browser.homeModules.default
        inputs.nvf.homeModules.default
        # Stylix 26.05 still themes Wayprompt after its removal from Home Manager.
        { stylix.targets.wayprompt.enable = false; }
      ];
      users.${user.name}.imports = [
        ./home.nix
      ];
    };
  };
}

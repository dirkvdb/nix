{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    system.stateVersion = "25.05"; # Version at install time, never change

    wsl.enable = true;
    wsl.defaultUser = "dirk";

    local = {
      user = {
        enable = true;
        name = "dirk";
        home-manager.enable = true;
        shell.package = pkgs.fish;
      };

      theme.preset = "everforest";

      system = {
        nix = {
          unfree.enable = true;
          nh.enable = true;
          ld.enable = true;
          flakes.enable = true;
        };

        utils = {
          dev = true;
          sysadmin = true;
        };
      };

      home-manager = {
        # keepassxc = {
        #   enable = true;
        #   databasePaths = [
        #     "/nas/ssd/secrets/Desktop.kdbx"
        #   ];
        #   keyfilePath = "/nas/secrets/desktop.key";
        # };
      };
    };
  };
}

{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  home-directory =
    if pkgs.stdenv.isDarwin then
      "/Users/${config.local.user.name}"
    else
      "/home/${config.local.user.name}";
in
{
  options.local.user = {
    enable = lib.mkEnableOption "Enable User";
    name = lib.mkOption {
      type = lib.types.str;
      default = "dirk";
      description = "User account name";
    };

    alias = lib.mkOption {
      type = lib.types.str;
      default = "Dirk Vanden Boer";
      description = "Full alias";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "dirk.vdb@gmail.com";
      description = "Email address";
    };

    homeDir = lib.mkOption {
      type = lib.types.str;
      default = "${home-directory}";
      description = "Home Directory Path";
    };

    home-manager.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable home-manager";
    };

    ghToken.enable = lib.mkEnableOption "Include GitHub access-tokens in nix.conf";

    shell = lib.mkOption {
      default = { };
      description = "Shell config for user";
      type = lib.types.submodule {
        options = {
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.fish;
            description = "User shell";
          };

          starship.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable starship";
          };
        };
      };
    };
  };

  options.local.desktop = {
    enable = lib.mkEnableOption "Enable desktop environment support";

    displayScale = lib.mkOption {
      type = lib.types.number;
      default = 1.0;
      example = 1.5;
      description = "Global display scale factor (e.g., 1.0 for normal, 1.5 for 150% scaling).";
    };
  };

  options.local.headless = lib.mkEnableOption "Headless environment (no desktop GUI)";

  options.local.apps.sops = {
    enable = lib.mkEnableOption "Enable sops";
    ageKeyFile = lib.mkOption {
      default = { };
      description = "ageKeyFile config";
      type = types.submodule {
        options = {
          path = lib.mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Path to age key file used for sops decryption.";
          };
        };
      };
    };
  };

  options.local.system.video.amd = {
    enable = lib.mkEnableOption "Enable AMD graphics support";
  };

  options.local.system.cpu = {
    cores = lib.mkOption {
      type = lib.types.int;
      default = 1;
      example = 4;
      description = "Number of CPU cores available in the system.";
    };
  };

  options.local.system.network = {
    enable = lib.mkEnableOption "Enable networking";
    firewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable firewall";
    };
    hostname = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Device hostname";
    };
  };

}

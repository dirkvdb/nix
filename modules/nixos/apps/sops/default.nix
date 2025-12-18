{ lib, config, ... }:
let
  inherit (lib)
    types
    ;
  cfg = config.local.apps.sops;

in
{
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

  # sops does not have official darwin support, but works through home-manager
  config = lib.mkIf cfg.enable (
    let
      inherit (config.local) user;
    in
    {
      sops = {
        age.keyFile = "/home/${user.name}/.config/sops/age/keys.txt";

        defaultSopsFile = ./secrets.yaml;
        defaultSopsFormat = "yaml";
        #defaultSymlinkPath = "/run/user/1000/secrets";
        #defaultSecretsMountPoint = "/run/user/1000/secrets.d";

        secrets.openai_api_key = {
          # sopsFile = ./secrets.yml.enc; # optionally define per-secret files
        };
      };
    }
  );
}

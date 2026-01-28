{
  lib,
  config,
  pkgs,
  ...
}:
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
      environment.systemPackages = with pkgs; [
        sops
      ];
      sops = {
        age.keyFile = "/home/${user.name}/.config/sops/age/keys.txt";

        defaultSopsFile = ./secrets.yaml;
        defaultSopsFormat = "yaml";

        secrets.openai_api_key = {
          owner = user.name;
        };

        secrets.github_token = {
          owner = user.name;
        };

        secrets.mqtt_pass = {
          owner = user.name;
        };

        secrets.ssh_websocat_host = {
          owner = user.name;
        };
      };
    }
  );
}

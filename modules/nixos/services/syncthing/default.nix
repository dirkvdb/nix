{
  lib,
  config,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.services.syncthing;
  hmCfg = config.home-manager.users.${user.name};
  hostname = config.local.system.network.hostname;
  sopsEnabled = config.local.apps.sops.enable or false;
in
{
  options.local.services.syncthing = {
    enable = lib.mkEnableOption "Enable Syncthing";

    shares.secrets = lib.mkEnableOption "Sync secrets folder from NAS to ~/.local/secrets";

    shares.secretsPath = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${hmCfg.xdg.dataHome}/secrets";
      description = "Absolute path where the secrets share is synced to";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = user.name;
      group = "users";
      configDir = "/home/${user.name}/.config/syncthing";
      cert = lib.mkIf sopsEnabled config.sops.secrets."syncthing/${hostname}_cert".path;
      key = lib.mkIf sopsEnabled config.sops.secrets."syncthing/${hostname}_key".path;
      openDefaultPorts = true;
      overrideDevices = true;
      overrideFolders = true;

      settings = {
        devices = {
          "nas" = {
            id = "L2PAKR7-MDMTDKP-PGGAKAO-TCY65EQ-NPYGJKJ-X7CE635-4YFEL2G-2HNHDQN";
            addresses = [
              "tcp://nas.local:22000"
            ];
          };
        };

        folders = lib.mkMerge [
          (lib.mkIf cfg.shares.secrets {
            "secrets" = {
              path = cfg.shares.secretsPath;
              devices = [ "nas" ];
              type = "sendreceive";
            };
          })
        ];
      };
    };

    # Store syncthing identity and NAS WAN address in sops so the device ID
    # is stable across reinstalls and the WAN hostname stays out of the store.
    sops.secrets = lib.mkIf sopsEnabled {
      "syncthing/${hostname}_cert" = {
        owner = user.name;
      };
      "syncthing/${hostname}_key" = {
        owner = user.name;
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.system.network.networkmanager;
in
{
  options.local.system.network.networkmanager = {
    enable = lib.mkEnableOption "Enable NetworkManager for network management";

    wifi = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable WiFi support in NetworkManager";
      };

      backend = lib.mkOption {
        type = lib.types.enum [
          "wpa_supplicant"
          "iwd"
        ];
        default = "iwd";
        description = "WiFi backend to use with NetworkManager";
      };

      powersave = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable WiFi power saving";
      };
    };

    ethernet = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable ethernet support in NetworkManager";
      };
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        impala
        networkmanagerapplet
      ];
      description = "Additional packages to install with NetworkManager";
    };

    vpn = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable VPN plugins for NetworkManager";
      };

      plugins = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          networkmanager-openvpn
          networkmanager-l2tp
        ];
        description = "VPN plugins to install";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Disable systemd-networkd when using NetworkManager
    systemd.network.enable = lib.mkForce false;
    networking.useNetworkd = lib.mkForce false;

    users.users.${user.name}.extraGroups = [ "networkmanager" ];

    # Enable NetworkManager
    networking.networkmanager = {
      enable = true;
      wifi = lib.mkIf cfg.wifi.enable {
        backend = cfg.wifi.backend;
        powersave = cfg.wifi.powersave;
      };
      dns = "systemd-resolved";
      plugins = lib.mkIf cfg.vpn.enable cfg.vpn.plugins;
    };

    # When NetworkManager uses iwd backend, it manages iwd internally
    # Do NOT separately enable iwd service as it will conflict
    # NetworkManager will start iwd automatically when wifi.backend = "iwd"

    # Install NetworkManager and related packages
    environment.systemPackages = cfg.extraPackages;

    # Add user-friendly network management tools
    programs.nm-applet.enable = lib.mkDefault true;

    assertions = [
      {
        assertion = !(config.local.system.network.ethernet.enable or false) || !cfg.enable;
        message = "Cannot enable both systemd-networkd ethernet and NetworkManager. Disable local.system.network.ethernet when using NetworkManager.";
      }
      {
        assertion = !(config.local.system.network.wifi.enable or false) || !cfg.enable;
        message = "Cannot enable both systemd-networkd wifi and NetworkManager. Disable local.system.network.wifi when using NetworkManager.";
      }
    ];
  };
}

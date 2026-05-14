{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.system.network.networkmanager;

  nordvpnConnections = {
    nordvpn-uk = "vpn/nordvpn-uk.conf";
    nordvpn-be = "vpn/nordvpn-be.conf";
    nordvpn-nl = "vpn/nordvpn-nl.conf";
    nordvpn-us = "vpn/nordvpn-us.conf";
  };
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
        networkmanagerapplet
        nmrs-gui
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
          networkmanager-l2tp
        ];
        description = "VPN plugins to install";
      };

      nordvpn = lib.mkEnableOption ''
        NordVPN WireGuard connections via NetworkManager.
        Imports configs for UK, Belgium, Netherlands and US into
        NetworkManager so they appear in nm-applet.
      '';
    };

    enableIpv6 = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable IPv6 system-wide. Disable to prevent IPv6 leaks when using VPN providers that do not support IPv6.";
    };

    localDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Local domains that should always be resolved via the local network DNS, even when a VPN is active.";
      example = [
        "arr"
        "local"
      ];
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

    networking.enableIPv6 = cfg.enableIpv6;

    # Import NordVPN WireGuard configs into NetworkManager so they
    # appear in nm-applet and can be toggled from the system tray.
    sops.secrets = lib.mkIf cfg.vpn.nordvpn (
      lib.mapAttrs' (name: secret: lib.nameValuePair secret { }) nordvpnConnections
    );

    systemd.services = lib.mkIf cfg.vpn.nordvpn (
      lib.mapAttrs' (
        name: secret:
        let
          secretPath = config.sops.secrets.${secret}.path;
        in
        lib.nameValuePair "${name}-nm-import" {
          description = "Import ${name} WireGuard config into NetworkManager";
          after = [
            "NetworkManager.service"
            "sops-nix.service"
          ];
          requires = [ "NetworkManager.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          path = [ pkgs.networkmanager ];
          script = ''
            # Remove stale profile and re-import from the current secret
            nmcli connection delete "${name}" 2>/dev/null || true
            nmcli connection import type wireguard file ${secretPath}
            # Ensure connection name matches the configured key
            imported=$(basename "${secretPath}" .conf)
            if [ "$imported" != "${name}" ]; then
              nmcli connection modify "$imported" connection.id "${name}"
            fi
            # Don't auto-connect at boot — toggle from nm-applet instead
            nmcli connection modify "${name}" connection.autoconnect no
            nmcli connection down "${name}" 2>/dev/null || true
          '';
        }
      ) nordvpnConnections
    );

    # Required so that WireGuard traffic is not dropped by reverse-path filtering
    networking.firewall.checkReversePath = lib.mkIf cfg.vpn.nordvpn "loose";

    # Set routing domains on non-VPN interfaces so local domain queries
    # always go to the local DNS server rather than the VPN's DNS.
    # ~<domain> is more specific than the VPN's catch-all ~. so
    # systemd-resolved will prefer it.
    networking.networkmanager.dispatcherScripts = lib.mkIf (cfg.localDomains != [ ]) [
      {
        source =
          let
            domains = lib.concatMapStringsSep " " (d: "~${d}") cfg.localDomains;
          in
          pkgs.writeScript "local-dns-routing" ''
            #!/bin/sh
            # On any interface coming up (including VPN), ensure local
            # routing domains are set on all active wifi/ethernet links.
            case "$2" in
              up|dhcp4-change)
                for dev in $(${pkgs.networkmanager}/bin/nmcli -t -f DEVICE,TYPE device status | grep -E ':(wifi|ethernet)$' | cut -d: -f1); do
                  ${pkgs.systemd}/bin/resolvectl domain "$dev" ${domains} 2>/dev/null || true
                done
                ;;
            esac
          '';
        type = "basic";
      }
    ];

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

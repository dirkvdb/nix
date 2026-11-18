{ lib, pkgs, ... }:
let
  homeSSID = "Network";
  homeSubnet = "192.168.1.0/24";
  # Ahead of Tailscale's rules (5210-5270). Suppress the default route so
  # traffic can still fall through to Tailscale if the LAN route is absent.
  rule = "priority 2500 to ${homeSubnet} lookup main suppress_prefixlength 0";

  updateRoutes = pkgs.writeShellApplication {
    name = "tailscale-home-network-routes";
    runtimeInputs = with pkgs; [
      iproute2
      networkmanager
      util-linux
    ];
    text = ''
      # Serialize boot/activation reconciliation and NetworkManager events.
      exec 9>/run/tailscale-home-network-routes.lock
      flock 9

      at_home=false
      if [[ "''${1:-}" != "--clear" ]]; then
        active_connections=$(nmcli --terse --escape no --fields UUID,TYPE connection show --active)
        while IFS=: read -r uuid connection_type; do
          [[ "$connection_type" == "802-11-wireless" ]] || continue
          # UUIDs are only used to query currently active Wi-Fi profiles;
          # the configured SSID, not the profile's name or UUID, is matched.
          ssid=$(nmcli --escape no --get-values 802-11-wireless.ssid connection show uuid "$uuid") || continue
          if [[ "$ssid" == ${lib.escapeShellArg homeSSID} ]]; then
            at_home=true
            break
          fi
        done <<< "$active_connections"
      fi

      # Remove only this module's exact rule, including any duplicate copies.
      while ip -4 rule del ${rule} 2>/dev/null; do :; done
      if "$at_home"; then
        ip -4 rule add ${rule}
      fi
    '';
  };
in
{
  # Keep remote subnet access enabled, even while using the direct LAN at home.
  services.tailscale.extraSetFlags = [ "--accept-routes=true" ];

  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeShellScript "tailscale-home-network-dispatcher" ''
        case "''${2:-}" in
          up|down|dhcp4-change|reapply)
            exec ${lib.getExe updateRoutes}
            ;;
        esac
      '';
    }
  ];

  # Dispatcher hooks handle connection changes; this also handles activation
  # while already connected, and cleans up the rule if the service is removed.
  systemd.services.tailscale-home-network-routes = {
    description = "Prefer the direct home LAN over Tailscale on home Wi-Fi";
    wantedBy = [ "multi-user.target" ];
    requires = [ "NetworkManager.service" ];
    after = [ "NetworkManager.service" ];
    before = [ "tailscaled-set.service" ];
    partOf = [ "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = lib.getExe updateRoutes;
      ExecStop = "${lib.getExe updateRoutes} --clear";
    };
  };
}

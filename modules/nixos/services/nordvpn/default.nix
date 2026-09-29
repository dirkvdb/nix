{
  lib,
  config,
  inputs,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.services.nordvpn;
  inherit (config.local) user;
in
{
  imports = [
    (let
      upstream = import "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/nordvpn.nix" {
        inherit config lib;
        pkgs = unstablePkgs;
      };
    in
    # The unstable module's manual page has no redirect in the 26.05 manual.
    upstream // { meta = builtins.removeAttrs upstream.meta [ "doc" ]; })
  ];

  options.local.services.nordvpn = {
    enable = lib.mkEnableOption "NordVPN service";

    localDns = lib.mkEnableOption "Route .arr domains to the local DNS server (192.168.1.13), bypassing the VPN";
  };

  config = lib.mkIf cfg.enable {
    services.nordvpn = {
      enable = true;
      package =
        if config.local.desktop.enable then
          unstablePkgs.nordvpn
        else
          unstablePkgs.nordvpn // { gui = unstablePkgs.emptyDirectory; };
    };

    users.users.${user.name}.extraGroups = [ "nordvpn" ];

    networking.firewall.checkReversePath = "loose";

    # Route .arr queries to the local DNS server instead of the VPN's DNS.
    services.resolved.settings = lib.mkIf cfg.localDns {
      Resolve = {
        DNS = "192.168.1.13";
        Domains = "~arr";
      };
    };

    # Reapply LAN discovery whenever the daemon starts (including restarts).
    systemd.services.nordvpnd.postStart = ''
      export HOME=/tmp
      for i in $(seq 1 10); do
        nordvpn status >/dev/null 2>&1 && break
        sleep 1
      done
      nordvpn set lan-discovery on || true
    '';
  };
}

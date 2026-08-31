{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.tether;
in
{
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    # Tether needs BlueZ's experimental bearer API for iPhone notification
    # mirroring and Bluetooth message support.
    systemd.services.bluetooth.serviceConfig.ExecStart = lib.mkForce [
      ""
      "${pkgs.bluez}/libexec/bluetooth/bluetoothd --experimental"
    ];

    # The iPhone only exposes its Messages and Contacts permissions after the
    # adapter presents itself as A/V Hands-Free (major 4, minor 8).
    systemd.services."tether-btclass@hci0" = {
      description = "Set Bluetooth class for Tether on hci0";
      after = [ "bluetooth.service" ];
      partOf = [ "bluetooth.service" ];
      wantedBy = [ "bluetooth.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        for _ in 1 2 3 4 5 6 7 8 9 10; do
          ${pkgs.bluez}/bin/btmgmt --index hci0 class 4 8 >/dev/null 2>&1
          if ${pkgs.bluez}/bin/btmgmt --index hci0 info 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "class 0x..0408"; then
            exit 0
          fi
          ${pkgs.coreutils}/bin/sleep 1
        done
        exit 1
      '';
    };
  };
}

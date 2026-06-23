{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.boot.initrd-bluetooth;
in
{
  options.local.system.boot.initrd-bluetooth = {
    enable = lib.mkEnableOption "Bluetooth in initrd for entering the FDE password with a wireless keyboard";

    extraFirmwarePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Additional firmware paths (relative to the firmware package's lib/firmware/)
        to include in the initrd for the Bluetooth adapter.

        Find your adapter's firmware with:
          dmesg | grep -i bluetooth | grep -i firmware
        or:
          journalctl -b | grep -i 'bluetooth.*firmware'
      '';
      example = [
        "intel/ibt-0041-0041.sfi"
        "intel/ibt-0041-0041.ddc"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.boot.initrd.systemd.enable;
        message = "local.system.boot.initrd-bluetooth requires boot.initrd.systemd.enable = true (graphical boot)";
      }
      {
        assertion = config.hardware.bluetooth.enable;
        message = "local.system.boot.initrd-bluetooth requires hardware.bluetooth.enable = true";
      }
    ];

    # Bluetooth kernel modules needed in the initrd
    boot.initrd.availableKernelModules = [
      "bluetooth"
      "btusb"
      "btintel" # Intel Bluetooth firmware loader
      "hid_generic"
      "hidp" # HID over Bluetooth (keyboard/mouse)
      "uhid" # User-space HID
    ];

    # Include Bluetooth firmware in the initrd so the adapter can initialise.
    boot.initrd.extraFirmwarePaths = cfg.extraFirmwarePaths;

    # D-Bus is required for bluetoothd
    boot.initrd.systemd.dbus.enable = true;

    # Override the initrd dbus config to include bluez's policy file.
    # The upstream dbus module only includes systemd's own policies;
    # bluetoothd needs its org.bluez bus name policy to start.
    boot.initrd.systemd.contents."/etc/dbus-1".source = lib.mkForce (
      pkgs.makeDBusConf.override {
        inherit (config.services.dbus) apparmor;
        dbus = config.services.dbus.dbusPackage;
        suidHelper = "/bin/false";
        serviceDirectories = [
          config.services.dbus.dbusPackage
          config.boot.initrd.systemd.package
          pkgs.bluez
        ];
      }
    );

    # Include bluez binaries, dbus policies, and rfkill in the initrd.
    # The dbus policy directory must be present because makeDBusConf
    # generates <includedir> entries that reference it.
    boot.initrd.systemd.storePaths = [
      "${pkgs.bluez}/libexec/bluetooth/bluetoothd"
      "${pkgs.bluez}/share/dbus-1/system.d"
      "${pkgs.bluez}/share/dbus-1/system-services"
      "${pkgs.util-linux}/bin/rfkill"
    ];

    # Copy Bluetooth pairing keys into the initrd so already-paired keyboards
    # can reconnect automatically. These live on the (unencrypted) boot
    # partition inside the initrd image.
    boot.initrd.secrets = {
      "/var/lib/bluetooth" = "/var/lib/bluetooth";
    };

    # Start bluetoothd early in the initrd, before the LUKS password prompt
    boot.initrd.systemd.services.bluetooth-initrd = {
      description = "Bluetooth service (initrd)";
      wantedBy = [ "sysinit.target" ];
      before = [
        "systemd-ask-password-console.service"
        "cryptsetup.target"
      ];
      after = [
        "systemd-udevd.service"
        "dbus.service"
      ];
      requires = [ "dbus.service" ];
      unitConfig = {
        DefaultDependencies = false;
      };
      serviceConfig = {
        Type = "dbus";
        BusName = "org.bluez";
        ExecStart = "${pkgs.bluez}/libexec/bluetooth/bluetoothd --noplugin=sap,avrcp -f /etc/bluetooth/main.conf";
        ExecStartPost = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
        NotifyAccess = "main";
      };
    };

    # Minimal bluetooth config for the initrd
    boot.initrd.systemd.contents."/etc/bluetooth/main.conf".text = ''
      [General]
      FastConnectable = true

      [Policy]
      AutoEnable = true
    '';
  };
}

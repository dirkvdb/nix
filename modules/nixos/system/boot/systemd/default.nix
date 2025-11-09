{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.system.boot.systemd;
  amd = config.local.system.video.amd.enable or false;
in
{
  options.local.system.boot.systemd = {
    enable = lib.mkEnableOption "Enable systemd bootloader";
    graphical = lib.mkEnableOption "Enable graphical boot without kernel messages";
    canTouchEfi = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow modifying EFI variables";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        boot.loader = {
          systemd-boot.enable = true;
          systemd-boot.consoleMode = "auto";
          efi.canTouchEfiVariables = cfg.canTouchEfi;
          timeout = 1;
        };
      }

      (lib.mkIf cfg.graphical {

        boot.consoleLogLevel = 3;
        boot.initrd.verbose = false;
        boot.initrd.systemd.enable = true;
        boot.kernelParams = [
          "quiet"
          "splash"
          "intremap=on"
          "boot.shell_on_fail"
          "udev.log_priority=3"
          "rd.systemd.show_status=auto"
          "vt.global_cursor_default=0"
          "fbcon=nodefer"
          "video=efifb:nobgrt" # disable firmware vendor logo
        ]
        ++ lib.optionals amd [ "amdgpu.modeset=1" ];

        # plymouth, showing after LUKS unlock
        boot.plymouth.enable = true;
        boot.plymouth.themePackages = [ pkgs.plymouth-theme-nixos ];
        boot.plymouth.theme = "nixos";
      })
    ]
  );
}

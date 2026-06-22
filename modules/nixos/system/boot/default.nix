{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.system.boot;
  amd = config.local.system.video.amd.enable;
in
{
  options.local.system.boot = {
    canTouchEfi = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow modifying EFI variables";
    };
    timeout = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Boot loader timeout in seconds";
    };
    graphical = lib.mkEnableOption "Enable graphical boot without kernel messages";
  };

  config = lib.mkMerge [
    {
      boot.loader = {
        efi.canTouchEfiVariables = cfg.canTouchEfi;
        timeout = cfg.timeout;
      };
    }

    (lib.mkIf cfg.graphical {
      boot.consoleLogLevel = 3;
      boot.initrd.verbose = false;
      boot.initrd.systemd.enable = true;
      boot.kernelParams = [
        "quiet"
        "intremap=on"
        "boot.shell_on_fail"
        "udev.log_priority=3"
        "rd.systemd.show_status=auto"
        "vt.global_cursor_default=0"
        "video=efifb:nobgrt" # disable firmware vendor logo
      ]
      ++ lib.optionals amd [ "amdgpu.modeset=1" ];

      stylix.targets.plymouth.enable = false;

      # plymouth, showing after LUKS unlock
      boot.plymouth.enable = true;
      boot.plymouth.themePackages = [ pkgs.plymouth-theme-nixos ];
      boot.plymouth.theme = "nixos";
    })
  ];
}

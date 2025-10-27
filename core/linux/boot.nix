{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixCfg.ethernet;
in
{
  options.nixCfg.graphicalBoot = {
    enable = lib.mkEnableOption "Enable graphical boot";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      packages = [
        pkgs.noto-fonts
      ];
    };

    environment.systemPackages = with pkgs; [
      nixos-icons
    ];

    boot = {
      # silence first boot output
      consoleLogLevel = 3;
      initrd.verbose = false;
      initrd.systemd.enable = true;
      kernelParams = [
        "quiet"
        "splash"
        "intremap=on"
        "boot.shell_on_fail"
        "udev.log_priority=3"
        "rd.systemd.show_status=auto"
      ];

      # plymouth, showing after LUKS unlock
      plymouth.enable = true;
      plymouth.font = "${pkgs.noto-fonts}/share/fonts/noto/NotoSans[wdth,wght].ttf";
      plymouth.logo = "${pkgs.nixos-icons}/share/icons/hicolor/128x128/apps/nix-snowflake.png";
    };
  };
}

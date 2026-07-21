{
  config,
  lib,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  isDesktop = config.local.desktop.enable or false;
  isHeadless = config.local.headless or false;
  isHyprlandEnabled = config.local.desktop.hyprland.enable or false;
  isNvidiaEnabled = config.local.system.video.nvidia.enable or false;
  cfg = config.local.desktop.waybar;
  mkUserHome = mkHome user.name;
in
{
  config = lib.mkIf (isDesktop && !isHeadless && isHyprlandEnabled && cfg.enable) (mkUserHome {
    services.hypridle = {
      enable = false;
      settings = {
        general = {
          after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms(\"on\")'";
          ignore_dbus_inhibit = false;
          lock_cmd = "hyprlock";
        };

        listener = [
          # Save power on short time away
          {
            timeout = 150; # 2.5min.
            on-timeout =
              (lib.optionalString config.local.services.wluma.enable "systemctl --user stop wluma.service && ")
              + "brightnessctl -s set 0"; # set monitor backlight to minimum, avoid 0 on OLED monitor.
            on-resume =
              "brightnessctl -r"
              + (lib.optionalString config.local.services.wluma.enable " && systemctl --user start wluma.service"); # monitor backlight restore.
          }
        ]
        ++ lib.optionals (!isNvidiaEnabled) [
          # Power off the monitor via DPMS after some time.
          # Skipped on NVIDIA: the proprietary driver does not reliably
          # reinitialise the display pipeline after dpms off → on, leaving
          # the screen permanently black. Brightness is already at 0 from
          # the listener above, so the display is effectively off anyway.
          {
            timeout = 600; # 10min
            on-timeout = "hyprctl dispatch 'hl.dsp.dpms(\"off\")'";
            on-resume = "hyprctl dispatch 'hl.dsp.dpms(\"on\")' && sleep 2.0 && hyprctl dispatch 'hl.dsp.dpms(\"on\")' && sleep 1.0 && hyprctl dispatch 'hl.dsp.dpms(\"on\")' && brightnessctl -r && hyprctl dispatch 'hl.dsp.focus({ urgent_or_last = true })'";
          }
        ]
        ++ [
          # Long time away - lock the screen
          {
            timeout = 7200; # 120min
            on-timeout = "hyprlock";
            on-resume = "hyprctl dispatch 'hl.dsp.focus({ urgent_or_last = true })'"; # Trigger a repaint to avoid empty workspace after unlocking
          }
        ];
      };
    };
  });
}

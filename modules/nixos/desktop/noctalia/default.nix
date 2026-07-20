{
  lib,
  pkgs,
  config,
  mkHome,
  ...
}:
let
  cfg = config.local.desktop.noctalia;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable or false;
  isHeadless = config.local.headless or false;
  isHyprlandEnabled = config.local.desktop.hyprland.enable or false;
  inherit (config.local) user;
  mkUserHome = mkHome user.name;
in
{
  options.local.desktop.noctalia = {
    enable = lib.mkEnableOption "Noctalia v5 (beta) desktop shell";
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !(cfg.enable && (config.local.desktop.waybar.enable or false));
          message = ''
            local.desktop.noctalia.enable and local.desktop.waybar.enable are
            mutually exclusive desktop shells; disable local.desktop.waybar
            to use Noctalia instead.
          '';
        }
      ];
    }
    (lib.mkIf cfg.enable {
      # Noctalia is a shell/bar; it still needs a compositor underneath.
      # Only takes effect if a host hasn't already set this explicitly.
      local.desktop.hyprland.enable = lib.mkDefault true;

      programs.noctalia = {
        enable = true;

        # Starts noctalia automatically after login via a systemd user
        # service, tied to the same graphical-session.target that UWSM
        # activates once Hyprland is up.
        systemd.enable = true;

        # Enables NetworkManager, Bluetooth, UPower, and a power profile service.
        recommendedServices.enable = true;
      };
    })
    (lib.mkIf (cfg.enable && isLinux && isDesktop && !isHeadless && isHyprlandEnabled) (mkUserHome {
      # Hyprland keybindings specific to this shell (Noctalia power menu).
      xdg.configFile."hypr/bindings-noctalia.lua".source = ./bindings.lua;

      # Oneshot gate that blocks until the StatusNotifierWatcher D-Bus name
      # appears. tray.target already orders After=noctalia.service, but
      # noctalia is Type=simple so systemd considers it "started" before the
      # tray is actually registered on D-Bus. By making tray.target also pull
      # in this service, dependent units (e.g. keepassxc) see a tray that is
      # genuinely ready.
      systemd.user.services.tray-ready = {
        Unit = {
          Description = "Wait for system tray (StatusNotifierWatcher) on D-Bus";
          After = [ "noctalia.service" ];
          Requisite = [ "noctalia.service" ];
        };

        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = toString (
            pkgs.writeShellScript "wait-for-tray" ''
              ${pkgs.glib}/bin/gdbus wait --session org.kde.StatusNotifierWatcher
            ''
          );
          TimeoutStartSec = 15;
        };
      };

      systemd.user.targets.tray.Unit = {
        Requires = [ "tray-ready.service" ];
        After = [ "tray-ready.service" ];
      };
    }))
  ];
}

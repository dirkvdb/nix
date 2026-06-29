{
  pkgs,
  config,
  lib,
  inputs,
  mkHome,
  unstablePkgs,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.local) theme;
  inherit (config.lib.stylix) colors;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable;
  isHyprlandEnabled = config.local.desktop.hyprland.enable or false;
  isNvidiaEnabled = config.local.system.video.nvidia.enable or false;
  sopsEnabled = config.local.apps.sops.enable or false;
  mkUserHome = mkHome user.name;

  # Directory holding all theme wallpapers. wpaperd will pick & rotate them.
  wallpapersDir = ../../../common/theme/wallpapers;

  # Border colors used in general and group config sections
  activeBorderColor = "rgb(${lib.strings.removePrefix "#" theme.uiAccentColor})";
  inactiveBorderColor = "rgba(${lib.strings.removePrefix "#" colors.base04}aa)";

  # Auto-start applications launched via hl.on("hyprland.start", ...)
  startupCommands = [
    "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"
    "sunsetr"
    "wl-paste --watch --primary wl-copy"
    "wl-clip-persist --clipboard both"
  ]
  ++ lib.optionals config.local.services.sunshine.enable [
    "hyprctl output create headless SUNSHINE && systemctl --user restart sunshine.service"
  ];
in
{
  imports = [
    ./bindings.nix
    ./hyprexpose.nix
    ./waybar.nix
    ./mako.nix
  ];

  config = lib.mkIf (isLinux && isDesktop && isHyprlandEnabled) (mkUserHome {
    stylix.targets.hyprland.enable = false;
    stylix.targets.wpaperd.image.enable = false;

    xdg.configFile."sunsetr".source = ../../dotfiles/sunsetr;
    xdg.configFile."hypr/settings.lua".source = ./settings.lua;
    xdg.configFile."hypr/bindings.lua".source = ./bindings.lua;

    # Ensure monitors.lua exists so require("monitors") doesn't fail before
    # hyprmoncfg writes the real file. Must be a regular file (not a store
    # symlink) so hyprmoncfg can overwrite it.
    home.activation.ensureMonitorsLua = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f "$HOME/.config/hypr/monitors.lua" ]; then
        mkdir -p "$HOME/.config/hypr"
        echo '-- Placeholder; hyprmoncfg will overwrite this.' > "$HOME/.config/hypr/monitors.lua"
      fi
    '';

    programs.hyprlock = {
      enable = true;
      settings = {
        background = {
          blur_passes = 3;
        };

        animations.ebabled = false;

        input-field = {
          size = "650, 100";
          position = "0, 0";
          halign = "center";
          valign = "center";

          outline_thickness = 4;

          placeholder_text = "Enter Password";
          fail_text = "<i>$FAIL ($ATTEMPTS)</i>";

          rounding = 8;
          shadow_passes = 0;
          fade_on_empty = false;
        };
      };
    };

    services.hypridle = {
      enable = true;
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

    # Use wpaperd to display and rotate wallpapers natively. It cycles through
    # all images in the configured directory based on `duration` and `sorting`,
    # so no custom systemd timer is required.
    services.wpaperd = {
      enable = true;
      package = unstablePkgs.wpaperd;
      settings = {
        any = {
          path = "${wallpapersDir}";
          duration = "30m";
          sorting = "random";
          mode = "center";
        };
      };
    };

    # Enable XDG portal for screen sharing, file pickers, etc.
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common.default = [
        "gtk"
        "hyprland"
      ];
    };

    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    }
    // lib.optionalAttrs sopsEnabled {
      COPILOT_GITHUB_TOKEN = config.sops.placeholder.copilot_github_token;
    };

    # Set via environment.d so systemd user services (uwsm app, Walker/elephant)
    # inherit the same Wayland and scaling variables as terminal-launched apps.
    systemd.user.sessionVariables = {
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      GDK_BACKEND = "wayland,x11,*";
      QT_QPA_PLATFORM = "wayland;xcb";
      SDL_VIDEODRIVER = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      OZONE_PLATFORM = "wayland";
    };

    wayland.windowManager.hyprland = {
      enable = true;

      portalPackage = pkgs.xdg-desktop-portal-hyprland;

      extraConfig = ''
        require("settings")
        require("bindings")
        require("monitors")
      '';

      # Session target management is handled by UWSM; the home-manager
      # built-in exec-once (env import + target activation) is not needed.
      systemd.enable = false;

      settings = {
        # Auto-start applications
        on = [
          {
            _args = [
              "hyprland.start"
              (lib.generators.mkLuaInline ''
                function()
                  ${lib.concatMapStringsSep "\n    " (
                    cmd: "hl.exec_cmd(${lib.generators.toLua { } cmd})"
                  ) startupCommands}
                end'')
            ];
          }
        ];

        # Monitor configuration: host-specific + catch-all for any connected display
        monitor = config.local.desktop.monitors ++ [
          {
            output = "";
            mode = "preferred";
            position = "auto";
            scale = toString (config.local.desktop.displayScale or 1.75);
          }
        ];

        # Theme-dependent config (border colors)
        config = {
          general.col = {
            active_border = activeBorderColor;
            inactive_border = inactiveBorderColor;
          };
          group.col = {
            border_active = activeBorderColor;
          };
        };
      };
    };
  });
}

{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (config.local) user;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable;
  # hyprexpo uses x86-only function hooks and doesn't work on ARM
  # See: https://github.com/hyprwm/hyprland-plugins/issues/438
  isX86 = pkgs.stdenv.isx86_64;

in
{
  imports = [
    ./bindings.nix
    ./waybar.nix
  ];

  home-manager.users.${user.name} = lib.mkIf (isLinux && isDesktop) {
    xdg.configFile."walker".source = ../../dotfiles/walker;
    xdg.configFile."sunsetr".source = ../../dotfiles/sunsetr;

    xdg.configFile."swayosd" = {
      source = ../../dotfiles/swayosd;
      recursive = true;
    };

    programs.hyprlock = {
      enable = true;
      settings = {
        source = "~/.local/share/theme/hyprlock.conf";
        background = {
          color = "$color";
          path = "~/.local/share/theme/wallpapers/wallpaper-1.jpg";
          blur_passes = 3;
        };

        animations.ebabled = false;

        input-field = {
          size = "650, 100";
          position = "0, 0";
          halign = "center";
          valign = "center";

          inner_color = "$inner_color";
          outer_color = "$outer_color";
          outline_thickness = 4;

          font_family = "CaskaydiaMono Nerd Font Propo";
          font_color = "$font_color";

          placeholder_text = "Enter Password";
          check_color = "$check_color";
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
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
          lock_cmd = "hyprlock";
        };

        listener = [
          # Save power on short time away
          {
            timeout = 150; # 2.5min.
            on-timeout = "brightnessctl -s set 0"; # set monitor backlight to minimum, avoid 0 on OLED monitor.
            on-resume = "brightnessctl -r"; # monitor backlight restore.
          }
          # Power of the monitor after some time
          {
            timeout = 600; # 10min
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on && sleep 2.0 && hyprctl dispatch dpms on && sleep 1.0 && hyprctl dispatch dpms on && brightnessctl -r";
          }
          # Long time away - lock the screen
          {
            timeout = 3600; # 60min
            on-timeout = "hyprlock";
          }
        ];
      };
    };

    services.hyprpaper = {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;

        preload = [
          "~/.local/share/theme/wallpapers/wallpaper-1.jpg"
        ];

        wallpaper = [
          ",~/.local/share/theme/wallpapers/wallpaper-1.jpg" # The comma means "all monitors"
        ];
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
      TERMINAL = "ghostty";
      EDITOR = "micro";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
    };

    wayland.windowManager.hyprland = {
      enable = true;

      portalPackage = pkgs.xdg-desktop-portal-hyprland;

      systemd = {
        enable = true;
        variables = [ "--all" ];
      };

      plugins = [
        pkgs.hyprlandPlugins.hyprscrolling
      ]
      ++ lib.optionals isX86 [
        # hyprexpo only works on x86_64 due to function hooking limitations
        pkgs.hyprlandPlugins.hyprexpo
      ];

      settings = {
        # Auto-start applications
        exec-once = [
          # Import environment variables into systemd user session
          # ''
          #   systemctl --user import-environment \
          #     WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP \
          #     ELECTRON_OZONE_PLATFORM_HINT GDK_BACKEND QT_QPA_PLATFORM SDL_VIDEODRIVER \
          #     MOZ_ENABLE_WAYLAND OZONE_PLATFORM
          # ''
          # ''
          #   dbus-update-activation-environment --systemd \
          #     WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP \
          #     ELECTRON_OZONE_PLATFORM_HINT GDK_BACKEND QT_QPA_PLATFORM SDL_VIDEODRIVER \
          #     MOZ_ENABLE_WAYLAND OZONE_PLATFORM
          # ''

          "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"
          "mako" # Notification daemon
          "swayosd-server" # On-screen display for volume/brightness
          "sunsetr"
          "hyprctl dismissnotify" # Dismiss the plugin loaded notification
        ];
        # Cursor size
        env = [
          "XCURSOR_SIZE,24"
          "HYPRCURSOR_SIZE,24"
          "XCURSOR_THEME,macOS"
          "HYPRCURSOR_THEME,macOS"

          # Force all apps to use Wayland
          "GDK_BACKEND,wayland,x11,*"
          "QT_QPA_PLATFORM,wayland;xcb"
          "SDL_VIDEODRIVER,wayland"
          "MOZ_ENABLE_WAYLAND,1"
          "ELECTRON_OZONE_PLATFORM_HINT,wayland"
          "OZONE_PLATFORM,wayland"
          "XDG_SESSION_TYPE,wayland"
          "XDG_SESSION_DESKTOP,Hyprland"
        ];

        xwayland = {
          force_zero_scaling = true;
        };

        # Don't show update on first launch
        ecosystem = {
          no_update_news = true;
        };

        # Good compromise for 27" or 32" 4K monitors (but fractional!)
        # env = GDK_SCALE,1.75
        monitor = ",preferred,auto,${toString (config.local.desktop.displayScale or 1.75)}";

        # Variables
        "$activeBorderColor" = "rgb(d3c6aa)";
        "$inactiveBorderColor" = "rgba(595959aa)";
        "$osdclient" =
          ''swayosd-client --monitor "$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')"'';

        dwindle = {
          #single_window_aspect_ratio = "4 3";
        };

        general = {
          # No gaps between windows
          gaps_in = 5;
          gaps_out = 10;

          border_size = 2;

          layout = "dwindle";
          # layout = "scrolling";
          #
          # Use master layout instead of dwindle
          # layout = "master";

          # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
          "col.active_border" = "$activeBorderColor";
          "col.inactive_border" = "$inactiveBorderColor";

          # Set to true enable resizing windows by clicking and dragging on borders and gaps
          resize_on_border = false;

          # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
          allow_tearing = false;
        };

        plugin.hyprexpo = lib.mkIf isX86 {
          columns = 3;
          gap_size = 5;
          bg_col = "rgb(111111)";
          workspace_method = "center current"; # [center/first] [workspace] e.g. first 1 or center m+1
          gesture_distance = 300; # how far is the "max" for the gesture
        };

        plugin.hyprscrolling = {
          column_width = 0.5;
          fullscreen_on_one_column = true;
        };

        group = {
          "col.border_active" = "$activeBorderColor";
        };

        decoration = {
          # Use round window corners
          rounding = 8;

          shadow = {
            enabled = true;
            range = 2;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };

          # https://wiki.hyprland.org/Configuring/Variables/#blur
          blur = {
            enabled = true;
            size = 3;
            passes = 3;
          };
        };

        # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
        dwindle = {
          pseudotile = true; # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
          preserve_split = true; # You probably want this
          force_split = 2; # Always split on the right
        };

        # https://wiki.hyprland.org/Configuring/Variables/#misc
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          focus_on_activate = true;
          anr_missed_pings = 3;
        };

        # https://wiki.hypr.land/Configuring/Variables/#cursor
        cursor = {
          no_hardware_cursors = false;
          enable_hyprcursor = true;
        };

        device = {
          name = "apple-mtp-multi-touch";
          # Keep palm brushes from registering as taps/clicks
          tap-to-click = false;
          clickfinger_behavior = true;

          # Disable touchpad while typing to prevent accidental palm touches
          disable_while_typing = true;
          scroll_factor = 0.3;
        };

        # Control your input devices
        # See https://wiki.hypr.land/Configuring/Variables/#input
        input = {
          # Use multiple keyboard layouts and switch between them with Left Alt + Right Alt
          # kb_layout = us,dk,eu
          kb_layout = "us";
          kb_options = "compose:ralt"; # ,grp:alts_toggle

          # Change speed of keyboard repeat
          repeat_rate = 35;
          repeat_delay = 200;

          # Start with numlock on by default
          numlock_by_default = true;

          # Increase sensitity for mouse/trackpack (default: 0)
          sensitivity = 0.2;

          touchpad = {
            # Use natural (inverse) scrolling
            natural_scroll = true;
            # Use two-finger clicks for right-click instead of lower-right corner
            clickfinger_behavior = true;
            tap-to-click = true;
            # Disable tap and drag (helps prevent accidental drags)
            drag_lock = false;
            # Tap and drag
            tap-and-drag = true;
          };
        };

        animations = {
          enabled = true;

          # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

          bezier = [
            "easeOutQuint,0.23,1,0.32,1"
            "easeInOutCubic,0.65,0.05,0.36,1"
            "linear,0,0,1,1"
            "almostLinear,0.5,0.5,0.75,1.0"
            "quick,0.15,0,0.1,1"
          ];

          animation = [
            "global, 1, 10, default"
            "border, 1, 5.39, easeOutQuint"
            "windows, 1, 4.79, easeOutQuint"
            "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
            "windowsOut, 1, 1.49, linear, popin 87%"
            "fadeIn, 1, 1.73, almostLinear"
            "fadeOut, 1, 1.46, almostLinear"
            "fade, 1, 3.03, quick"
            "layers, 1, 3.81, easeOutQuint"
            "layersIn, 1, 4, easeOutQuint, fade"
            "layersOut, 1, 1.5, linear, fade"
            "fadeLayersIn, 1, 1.79, almostLinear"
            "fadeLayersOut, 1, 1.39, almostLinear"
            "workspaces, 0, 0, ease"
            # minimal fade when switching workspaces
            "workspaces, 1, 1, default, fade"
          ];
        };

        layerrule = [
          "noanim, walker"
          # Remove 1px border around hyprshot screenshots
          "noanim, selection"
        ];

        workspace = [
          "1, name:cmd, persistent:true"
          "2, name:web, persistent:true"
          "3, name:dev, persistent:true, rounding:false, decorate:false, gapsin:0, gapsout:0"
          "4, name:scratch, persistent:true"
          "5, name:scratch, persistent:true"
          "6, name:vcs, persistent:true"
          "7, name:chat, persistent:true"
          "8, name:com, persistent:true"
        ];

        windowrule = [
          # disable the window opacity
          "opacity 1 1, class:.*"
          # Floating windows
          "float, tag:floating-window"
          "center, tag:floating-window"
          "size 1024 768, tag:floating-window"
          # Float LocalSend and fzf file picker
          "float, class:(Share|localsend)"
          "center, class:(Share|localsend)"
          # Define terminal tag to style them uniformly
          "tag +terminal, class:(Alacritty|kitty|com.mitchellh.ghostty)"
          "float, class:org.gnome.Calculato"
          "tag +floating-window, class:(blueberry.py|io.github.kaii_lb.Overskride|Impala|Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty|About|TUI.float|org.keepassxc.KeePassXC)"
          "tag +floating-window, class:(xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus), title:^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files)"
          # Browser types
          "tag +chromium-based-browser, class:((google-)?[cC]hrom(e|ium)|[bB]rave-browser|Microsoft-edge|Vivaldi-stable|helium)"
          "tag +firefox-based-browser, class:([fF]irefox|zen|librewolf)"

          # Force chromium-based browsers into a tile to deal with --app bug
          "tile, tag:chromium-based-browser"

          # Picture-in-picture overlays
          "tag +pip, title:(Picture.?in.?[Pp]icture)"
          "float, tag:pip"
          "pin, tag:pip"
          "size 600 338, tag:pip"
          "keepaspectratio, tag:pip"
          "noborder, tag:pip"
          "opacity 1 1, tag:pip"
          "move 100%-w-40 4%, tag:pip"

          # No password manager screenshare
          "noscreenshare, class:^(Bitwarden|org.keepassxc.KeePassXC)$"

          # Open browsers on workspace 2 when launched with SUPER+B
          "workspace 2, class:(vivaldi-stable)"
          "workspace 2, class:(firefox|Firefox|librewolf)"
          "workspace 2, class:(zen|zen-beta)"

          # Open Zed editor on workspace 3
          "workspace 3, class:(dev.zed.Zed)"
          # Open File explorers on workspace 3
          "workspace 4, class:(org.gnome.Nautilus|thunar)"

          "workspace 6, class:(sublime_merge)"
          "workspace 7, class:(Slack)"
          "workspace 8, class:(outlook-for-linux)"
          "workspace 8, class:(teams-for-linux)"
        ];
      };
    };
  };
}

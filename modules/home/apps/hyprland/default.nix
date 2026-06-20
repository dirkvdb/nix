{
  pkgs,
  config,
  lib,
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

          #inner_color = "$inner_color";
          #outer_color = "$outer_color";
          outline_thickness = 4;

          #font_family = "CaskaydiaMono Nerd Font Propo";
          #font_color = "$font_color";

          placeholder_text = "Enter Password";
          #check_color = "$check_color";
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
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on && sleep 2.0 && hyprctl dispatch dpms on && sleep 1.0 && hyprctl dispatch dpms on && brightnessctl -r && hyprctl dispatch focuswindow"; # Trigger a repaint to avoid empty workspace after waking up
          }
        ]
        ++ [
          # Long time away - lock the screen
          {
            timeout = 7200; # 120min
            on-timeout = "hyprlock";
            on-resume = "hyprctl dispatch focuswindow"; # Trigger a repaint to avoid empty workspace after unlocking
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

      # If ~/.config/hypr/monitors.conf exists (written by an external tool such
      # as nwg-displays), use it instead of the NixOS-configured monitors above.
      # Because extraConfig is appended after settings, the sourced file's
      # monitor directives override the inline ones for matching outputs.
      extraConfig = ''
        source = ~/.config/hypr/monitors.conf
      '';

      # Session target management is handled by UWSM; the home-manager
      # built-in exec-once (env import + target activation) is not needed.
      systemd.enable = false;

      plugins = [
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
          "sunsetr"
          "hyprctl dismissnotify" # Dismiss the plugin loaded notification
          # Sync PRIMARY selection → CLIPBOARD so mouse-selected text is pasteable with Ctrl+V
          "wl-paste --watch --primary wl-copy"
          # Keep clipboard contents alive after the source application closes
          "wl-clip-persist --clipboard both"
        ]
        ++ lib.optionals config.local.services.sunshine.enable [
          # Create the headless SUNSHINE output and (re)start sunshine so it
          # enumerates the new output and `output_name = 2` resolves to it.
          # Without the restart, sunshine has already cached the output list
          # from before this exec-once runs and binds to the wrong monitor.
          "hyprctl output create headless SUNSHINE && systemctl --user restart sunshine.service"
        ];
        env = [
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
        monitor = config.local.desktop.monitors ++ [
          ",preferred,auto,${toString (config.local.desktop.displayScale or 1.75)}"
        ];

        # Variables
        "$activeBorderColor" = "rgb(${lib.strings.removePrefix "#" theme.uiAccentColor})";
        "$inactiveBorderColor" = "rgba(${lib.strings.removePrefix "#" colors.base04}aa)";

        dwindle = {
          #single_window_aspect_ratio = "4 3";
        };

        general = {
          gaps_in = 3;
          gaps_out = 6;

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

        # https://wiki.hyprland.org/Configuring/Variables/#debug
        # debug = {
        #   overlay = true;
        # };

        # https://wiki.hypr.land/Configuring/Variables/#cursor
        cursor = {
          no_hardware_cursors = false;
          enable_hyprcursor = true;
        };

        device = [
          {
            name = "apple-mtp-multi-touch";
            # Keep palm brushes from registering as taps/clicks
            tap-to-click = false;
            clickfinger_behavior = true;

            # Disable touchpad while typing to prevent accidental palm touches
            disable_while_typing = true;
            scroll_factor = 0.3;
          }
          {
            name = "apple-mtp-keyboard";
            # Note: Caps Lock -> Escape and Right Alt -> Caps Lock are handled by kanata
            # See services.kanata configuration in the host configuration
            kb_options = "";
          }
        ];

        # Control your input devices
        # See https://wiki.hypr.land/Configuring/Variables/#input
        input = {
          # Use multiple keyboard layouts and switch between them with Left Alt + Right Alt
          # kb_layout = us,dk,eu
          kb_layout = "us";
          kb_options = "caps:escape"; # Map Caps Lock to Escape

          # Change speed of keyboard repeat
          repeat_rate = 35;
          repeat_delay = 300;

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
          "match:namespace walker, no_anim true"
          # Remove 1px border around hyprshot screenshots
          "match:namespace selection, no_anim true"
        ];

        workspace = [
          "3, rounding:false, decorate:false, gapsin:1, gapsout:1"
          "5, layoutopt:orientation:left, layout:scrolling"
        ];

        windowrule = [
          # disable the window opacity
          "match:class .*, opacity 1 1"
          # Floating windows
          "match:tag floating-window, float true"
          "match:tag floating-window, center true"
          "match:tag floating-window, size 1024 768"
          # Float LocalSend and fzf file picker
          "match:class (Share|localsend), float true"
          "match:class (Share|localsend), center true"
          # Define terminal tag to style them uniformly
          "match:class (Alacritty|kitty|com.mitchellh.ghostty), tag +terminal"
          "match:class org.gnome.Calculato, float true"
          "match:class com.github.finefindus.eyedropper, float true"
          "match:class (blueberry.py|io.github.kaii_lb.Overskride|Impala|Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty|About|TUI.float|org.keepassxc.KeePassXC), tag +floating-window"
          "match:class (xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus), match:title ^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files), tag +floating-window"
          # Browser types
          "match:class ((google-)?[cC]hrom(e|ium)|[bB]rave-browser|Microsoft-edge|Vivaldi-stable|helium), tag +chromium-based-browser"
          "match:class ([fF]irefox|zen|librewolf), tag +firefox-based-browser"

          # Force chromium-based browsers into a tile to deal with --app bug
          "match:tag chromium-based-browser, tile true"

          # Picture-in-picture overlays
          "match:title (Picture.?in.?[Pp]icture), tag +pip"
          "match:tag pip, float true"
          "match:tag pip, pin true"
          "match:tag pip, size 600 338"
          "match:tag pip, keep_aspect_ratio true"
          "match:tag pip, border_size 0"
          "match:tag pip, opacity 1 1"
          "match:tag pip, move 100%-w-40 4%"

          # No password manager screenshare
          "match:class ^(Bitwarden|org.keepassxc.KeePassXC)$, no_screen_share true"

          # Open browsers on workspace 2 when launched
          "match:class (vivaldi-stable), workspace 2"
          "match:class (firefox|Firefox|librewolf), workspace 2"
          "match:class (zen|zen-beta), workspace 2"

          # Open Zed editor on workspace 3
          "match:class (dev.zed.Zed), workspace 3"
          # Open File explorers on workspace 5
          "match:class (org.gnome.Nautilus|thunar), workspace 5"

          # Open Spotify on workspace 9 (web app class is derived from URL by Chromium on Wayland)
          "match:class (Spotify|chrome-open\.spotify\.com__.*), workspace 9"

          "match:class (sublime_merge), workspace 6"
          "match:class (slack), workspace 7"
          "match:class (outlook-for-linux|chrome-outlook\\.office365\\.com__.*), workspace 8"
          "match:class (teams-for-linux), workspace 8"

          # Fullscreen border color indicator
          "match:fullscreen true, border_color rgb(FFCC66) rgb(DEC186)"
          # Float specific apps
          "match:class ^(org\.nmrs\.ui)$, float true"
          "match:class ^(nordvpn-gui)$, float true"
          # Fladder media player fullscreen
          "match:class ^(Fladder)$, fullscreen true"
          "match:class ^(Fladder)$, fullscreen_state 2 2"
          "match:class ^(Fladder)$, border_size 0"
        ];
      };
    };
  });
}

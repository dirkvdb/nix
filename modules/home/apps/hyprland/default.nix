{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (config.local) user;
  isLinux = pkgs.stdenv.isLinux;
  # hyprexpo uses x86-only function hooks and doesn't work on ARM
  # See: https://github.com/hyprwm/hyprland-plugins/issues/438
  isX86 = pkgs.stdenv.isx86_64;

  # Get CPU core count from system config
  cpuCores = config.local.system.cpu.cores;

  # Generate CPU icon placeholders based on core count
  cpuIconPlaceholders = lib.concatStrings (lib.genList (i: "{icon${toString i}}") cpuCores);

  # Generate waybar config with dynamic CPU format
  waybarConfigContent = lib.generators.toJSON { } {
    reload_style_on_change = true;
    layer = "top";
    position = "top";
    spacing = 0;
    height = 26;
    modules-left = [
      "custom/nixmenu"
      "hyprland/workspaces"
    ];
    modules-center = [ "clock" ];
    modules-right = [
      "cpu"
      "battery"
      "tray"
      "bluetooth"
      "network"
      "pulseaudio"
    ];

    "hyprland/workspaces" = {
      on-click = "activate";
      format = "{icon}";
      format-icons = {
        default = "";
        "1" = "1";
        "2" = "2";
        "3" = "3";
        "4" = "4";
        "5" = "5";
        "6" = "6";
        "7" = "7";
        "8" = "8";
        "9" = "9";
        active = "󱓻";
      };
      persistent-workspaces = {
        "1" = [ ];
        "2" = [ ];
        "3" = [ ];
        "4" = [ ];
        "5" = [ ];
        "6" = [ ];
        "7" = [ ];
        "8" = [ ];
      };
    };

    "custom/nixmenu" = {
      format = "<span font='omarchy'></span>";
      on-click = "nixcfg-launch-walker";
      on-click-right = "nixcfg-launch-terminal";
      tooltip-format = "Applications Menu\n\nSuper + Space";
    };

    cpu = {
      interval = 2;
      format = "  ${cpuIconPlaceholders}";
      format-icons = [
        "<span> </span>"
        "<span color='#a7c080'>▁</span>"
        "<span color='#a7c080'>▂</span>"
        "<span color='#83c092'>▃</span>"
        "<span color='#83c092'>▄</span>"
        "<span color='#dbbc7f'>▅</span>"
        "<span color='#dbbc7f'>▆</span>"
        "<span color='#e69875'>▇</span>"
        "<span color='#e67e80'>█</span>"
      ];
      on-click = "ghostty -e btop";
    };

    clock = {
      format = "{:L%A %H:%M}";
      format-alt = "{:L%d %B W%V %Y}";
      tooltip = false;
    };

    network = {
      format-icons = [
        "󰤯"
        "󰤟"
        "󰤢"
        "󰤥"
        "󰤨"
      ];
      format = "{icon}";
      format-wifi = "{icon}";
      format-ethernet = "󰀂";
      format-disconnected = "󰤮";
      tooltip-format-wifi = "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
      tooltip-format-ethernet = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
      tooltip-format-disconnected = "Disconnected";
      interval = 3;
      spacing = 1;
      on-click = "nixcfg-launch-wifi";
    };

    battery = {
      format = "{capacity}% {icon}";
      format-discharging = "{icon}";
      format-charging = "{icon}";
      format-plugged = "";
      format-icons = {
        charging = [
          "󰢜"
          "󰂆"
          "󰂇"
          "󰂈"
          "󰢝"
          "󰂉"
          "󰢞"
          "󰂊"
          "󰂋"
          "󰂅"
        ];
        default = [
          "󰁺"
          "󰁻"
          "󰁼"
          "󰁽"
          "󰁾"
          "󰁿"
          "󰂀"
          "󰂁"
          "󰂂"
          "󰁹"
        ];
      };
      format-full = "󰂅";
      tooltip-format-discharging = "{power:>1.0f}W↓ {capacity}%";
      tooltip-format-charging = "{power:>1.0f}W↑ {capacity}%";
      interval = 5;
      on-click = "nixcfg-menu power";
      states = {
        warning = 20;
        critical = 10;
      };
    };

    bluetooth = {
      format = "";
      format-disabled = "󰂲";
      format-connected = "";
      tooltip-format = "Devices connected: {num_connections}";
      on-click = "overskride";
    };

    pulseaudio = {
      format = "{icon}";
      on-click = "ghostty --class=Wiremix -e wiremix";
      on-click-right = "pamixer -t";
      tooltip-format = "Playing at {volume}%";
      scroll-step = 5;
      format-muted = "";
      format-icons = {
        default = [
          ""
          ""
          ""
        ];
      };
    };

    "group/tray-expander" = {
      orientation = "inherit";
      drawer = {
        transition-duration = 600;
        children-class = "tray-group-item";
      };
      modules = [
        "custom/expand-icon"
        "tray"
      ];
    };

    "custom/expand-icon" = {
      format = " ";
      tooltip = false;
    };

    tray = {
      icon-size = 12;
      spacing = 12;
    };
  };
in
{
  home-manager.users.${user.name} = lib.mkIf isLinux {
    xdg.configFile."waybar/config.jsonc".text = waybarConfigContent;
    xdg.configFile."waybar/style.css".source = ../../dotfiles/waybar/style.css;
    xdg.configFile."walker".source = ../../dotfiles/walker;
    xdg.configFile."sunsetr".source = ../../dotfiles/sunsetr;

    xdg.configFile."swayosd" = {
      source = ../../dotfiles/swayosd;
      recursive = true;
    };

    # Configure waybar with systemd service to ensure proper PATH
    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        target = "hyprland-session.target";
      };
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
            on-timeout = "brightnessctl -s set 10"; # set monitor backlight to minimum, avoid 0 on OLED monitor.
            on-resume = "brightnessctl -r"; # monitor backlight restore.
          }
          # Power of the monitor after some time
          {
            timeout = 600; # 10min
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = ''
              bash -lc '
                hyprctl dispatch dpms on
                # give the link time to train
                sleep 1.0
                # restore brightness *after* DPMS is up
                brightnessctl -r
                # belt-and-suspenders: one more dpms on after brightness restore
                hyprctl dispatch dpms on
              '
            '';
          }
          # Long time away - lock the screen
          {
            timeout = 3600; # 1hr
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
          # sensitivity = 0.35

          touchpad = {
            # Use natural (inverse) scrolling
            natural_scroll = true;
            # Use two-finger clicks for right-click instead of lower-right corner
            clickfinger_behavior = true;
            # Control the speed of your scrolling
            # Increased from 0.4 to 1.0 for more responsive scrolling
            # Higher values (1.0-2.0) give a smoother feel that mimics inertia
            scroll_factor = 1.0;
            # Disable touchpad while typing to prevent accidental palm touches
            disable_while_typing = true;
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

        "$mod" = "SUPER";
        "$terminal" = "ghostty";
        "$browser" = "zen-beta";
        "$applauncher" = "nc -U /run/user/1000/walker/walker.sock";

        bind = [
          # scrolling layout controls
          "$mod SHIFT, L, layoutmsg, movewindowto r"
          "$mod SHIFT, H, layoutmsg, movewindowto l"
          "$mod SHIFT, I, layoutmsg, promote"
          "$mod SHIFT ALT, L, layoutmsg, move +col"
          "$mod SHIFT ALT, H, layoutmsg, move -col"

          # tiling layout controls
          # Swap active window with the one next to it with SUPER + SHIFT + arrow keys (VIM style)
          #"$mod SHIFT, H, movewindow, l"
          #"$mod SHIFT, L, movewindow, r"
          "$mod SHIFT, K, movewindow, u"
          "$mod SHIFT, J, movewindow, d"
          "$mod, backslash, togglesplit"
        ];

        bindm = [
          # mouse movements
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
          "$mod ALT, mouse:272, resizewindow"
        ];

        bindld = [
          ", XF86PowerOff, Power menu, exec, nixcfg-menu system"
        ];

        bindd = [
          "$mod, SPACE, Launch apps, exec, $applauncher"
        ]
        # Export workspace overview with SUPER + ~ (only on x86_64)
        ++ lib.optionals isX86 [
          "$mod, GRAVE, Workspace overview, hyprexpo:expo, toggle"
        ]
        ++ [
          "$mod ALT, SPACE, Menu, exec, nixcfg-menu"

          "$mod, ESCAPE, Power menu, exec, nixcfg-menu system"
          "$mod, RETURN, Terminal, exec, $terminal --working-directory=\"$(nixcfg-cmd-terminal-cwd)\""
          "$mod, B, Browser, exec, nixcfg-launch-or-focus $browser"
          "$mod SHIFT, B, Browser (new instance), exec, $browser"
          "$mod, D, Dev editor, exec, zeditor"
          "$mod, E, File manager, exec, nautilus --new-window"
          "$mod SHIFT, A, ChatGPT, exec, nixcfg-launch-or-focus-webapp ChatGPT \"https://chatgpt.com\""
          "$mod SHIFT, M, Music, exec, nixcfg-launch-or-focus spotify"
          "$mod SHIFT, Y, Youtube, exec, nixcfg-launch-or-focus-webapp Youtube \"https://youtube.com/\""
          "$mod SHIFT, W, Whatsapp, exec, nixcfg-launch-or-focus-webapp Whatsapp \"https://web.whatsapp.com/\""
          "$mod SHIFT, E, Email, exec, nixcfg-launch-or-focus-webapp GMail \"https://mail.google.com\""
          "$mod SHIFT, slash, Passwords, exec, bitwarden"
          "$mod, M, Music, exec, nixcfg-launch-or-focus spotify"
          "$mod, W, Close active window, killactive,"
          "$mod, K, Show key bindings, exec, nixcfg-menu-keybindings"
          "$mod, T, Activity, exec, $terminal -e btop"
          "CONTROL SHIFT, V, Clipboard, exec, walker --provider clipboard --theme clipboard"
          "$mod SHIFT, O, Office applications, exec, systemctl --user start work.target"
          "$mod SHIFT ALT, O, Close office applications, exec, systemctl --user stop work.target"

          "$mod CTRL, I, Toggle locking on idle, exec, nixcfg-toggle-idle"
          "$mod CTRL, N, Toggle nightlight, exec, nixcfg-toggle-nightlight"
          "$mod CTRL, S, Share, exec, nixcfg-menu share"

          # Control tiling
          "$mod SHIFT, V, Toggle floating, togglefloating"
          "$mod SHIFT, F, Maximize App Window, fullscreen, 1"
          "$mod ALT, F, Full width, fullscreen, 0"

          "$mod, code:20, Expand window left, resizeactive, -100 0" # - key
          "$mod, code:21, Shrink window left, resizeactive, 100 0" # = key
          "$mod SHIFT, code:20, Shrink window up, resizeactive, 0 -100"
          "$mod SHIFT, code:21, Expand window down, resizeactive, 0 100"

          # Move focus with SUPER + arrow keys
          "$mod, LEFT, Move focus left, movefocus, l"
          "$mod, RIGHT, Move focus right, movefocus, r"
          "$mod, UP, Move focus up, movefocus, u"
          "$mod, DOWN, Move focus down, movefocus, d"
          # Move focus with SUPER + vim arrow keys
          "$mod, H, Move focus left, movefocus, l"
          "$mod, L, Move focus right, movefocus, r"
          "$mod, K, Move focus up, movefocus, u"
          "$mod, J, Move focus down, movefocus, d"

          # Switch workspaces with SUPER + [0-9]
          "$mod, code:10, Switch to workspace 1, workspace, 1"
          "$mod, code:11, Switch to workspace 2, workspace, 2"
          "$mod, code:12, Switch to workspace 3, workspace, 3"
          "$mod, code:13, Switch to workspace 4, workspace, 4"
          "$mod, code:14, Switch to workspace 5, workspace, 5"
          "$mod, code:15, Switch to workspace 6, workspace, 6"
          "$mod, code:16, Switch to workspace 7, workspace, 7"
          "$mod, code:17, Switch to workspace 8, workspace, 8"
          "$mod, code:18, Switch to workspace 9, workspace, 9"
          "$mod, code:19, Switch to workspace 10, workspace, 10"

          # Move active window to a workspace with SUPER + SHIFT + [0-9]
          "$mod SHIFT, code:10, Move window to workspace 1, movetoworkspace, 1"
          "$mod SHIFT, code:11, Move window to workspace 2, movetoworkspace, 2"
          "$mod SHIFT, code:12, Move window to workspace 3, movetoworkspace, 3"
          "$mod SHIFT, code:13, Move window to workspace 4, movetoworkspace, 4"
          "$mod SHIFT, code:14, Move window to workspace 5, movetoworkspace, 5"
          "$mod SHIFT, code:15, Move window to workspace 6, movetoworkspace, 6"
          "$mod SHIFT, code:16, Move window to workspace 7, movetoworkspace, 7"
          "$mod SHIFT, code:17, Move window to workspace 8, movetoworkspace, 8"
          "$mod SHIFT, code:18, Move window to workspace 9, movetoworkspace, 9"
          "$mod SHIFT, code:19, Move window to workspace 10, movetoworkspace, 10"

          # Toggle groups
          "$mod, G, Toggle window grouping, togglegroup"
          "$mod ALT, G, Move active window out of group, moveoutofgroup"

          # Join groups
          "$mod ALT, LEFT, Move window to group on left, moveintogroup, l"
          "$mod ALT, RIGHT, Move window to group on right, moveintogroup, r"
          "$mod ALT, UP, Move window to group on top, moveintogroup, u"
          "$mod ALT, DOWN, Move window to group on bottom, moveintogroup, d"

          # Navigate a single set of grouped windows
          "$mod ALT, TAB, Next window in group, changegroupactive, f"
          "$mod ALT SHIFT, TAB, Previous window in group, changegroupactive, b"

          # Activate window in a group by number
          # "$mod ALT, 1, Switch to group window 1, changegroupactive, 1"
          # "$mod ALT, 2, Switch to group window 2, changegroupactive, 2"
          # "$mod ALT, 3, Switch to group window 3, changegroupactive, 3"
          # "$mod ALT, 4, Switch to group window 4, changegroupactive, 4"
          # "$mod ALT, 5, Switch to group window 5, changegroupactive, 5"

          # Screenshots
          "$mod ALT, 4, Screenshot of region, exec, nixcfg-cmd-screenshot"
          "$mod ALT, 3, Screenshot of window, exec, nixcfg-cmd-screenshot window"
          "$mod ALT, 2, Screenshot of display, exec, nixcfg-cmd-screenshot output"

          # Color picker
          "$mod ALT, 5, Color picker, exec, pkill hyprpicker || hyprpicker -a"
        ];

        bindeld = [
          # Laptop multimedia keys for volume and LCD brightness (with OSD)
          ",XF86AudioRaiseVolume, Volume up, exec, $osdclient --output-volume raise"
          ",XF86AudioLowerVolume, Volume down, exec, $osdclient --output-volume lower"
          ",XF86AudioMute, Mute, exec, $osdclient --output-volume mute-toggle"
          ",XF86AudioMicMute, Mute microphone, exec, $osdclient --input-volume mute-toggle"
          ",XF86MonBrightnessUp, Brightness up, exec, $osdclient --brightness +10"
          ",XF86MonBrightnessDown, Brightness down, exec, $osdclient --brightness -10"

          # Precise 1% multimedia adjustments with Alt modifier
          "ALT, XF86AudioRaiseVolume, Volume up precise, exec, $osdclient --output-volume +1"
          "ALT, XF86AudioLowerVolume, Volume down precise, exec, $osdclient --output-volume -1"
          "ALT, XF86MonBrightnessUp, Brightness up precise, exec, $osdclient --brightness +1"
          "ALT, XF86MonBrightnessDown, Brightness down precise, exec, $osdclient --brightness -1"
        ];

        layerrule = [
          "noanim, walker"
          # Remove 1px border around hyprshot screenshots
          "noanim, selection"
        ];

        workspace = [
          "1, name:cmd, persistent:true"
          "2, name:web, persistent:true"
          "3, name:dev, persistent:true, rounding:false, decorate:false, gapsin:0, gapsout:1"
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
          "size 800 600, tag:floating-wi"
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

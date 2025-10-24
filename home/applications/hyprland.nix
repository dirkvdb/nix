{ pkgs, ... }:
{
  home.file = {
    ".config/walker" = {
      source = ../../dotfiles/walker;
    };
    ".config/waybar" = {
      source = ../../dotfiles/waybar;
    };
  };

  # Configure waybar with systemd service to ensure proper PATH
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;

    # plugins = [
    #   pkgs.hyprlandPlugins.hyprexpo;
    # ];

    settings = {
      # Auto-start applications
      exec-once = [
        "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"
        "exec-once = uwsm-app -- waybar"
      ];
      # Cursor size
      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"

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
      monitor = ",preferred,auto,1.666667";

      # Variables
      "$activeBorderColor" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
      "$inactiveBorderColor" = "rgba(595959aa)";

      general = {
        # No gaps between windows
        gaps_in = 5;
        gaps_out = 10;

        border_size = 2;

        layout = "dwindle";
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
        disable_splash_rendering  = true;
        focus_on_activate = true;
        anr_missed_pings = 3;
      };

      # https://wiki.hypr.land/Configuring/Variables/#cursor
      cursor = {
        hide_on_key_press = true;
      };

      # Control your input devices
      # See https://wiki.hypr.land/Configuring/Variables/#input
      input = {
        # Use multiple keyboard layouts and switch between them with Left Alt + Right Alt
        # kb_layout = us,dk,eu
        kb_layout = "us";
        kb_options = "compose:ralt"; # ,grp:alts_toggle

        # Change speed of keyboard repeat
        repeat_rate = 40;
        repeat_delay = 200;

        # Start with numlock on by default
        numlock_by_default = true;

        # Increase sensitity for mouse/trackpack (default: 0)
        # sensitivity = 0.35

        touchpad = {
          # Use natural (inverse) scrolling
          # natural_scroll = true

          # Use two-finger clicks for right-click instead of lower-right corner
          # clickfinger_behavior = true

          # Control the speed of your scrolling
          scroll_factor = 0.4;
        };
      };

      "$mod" = "SUPER";
      "$terminal" = "uwsm app -- wezterm";
      "$browser" = "uwsm app -- firefox";

      bindm = [
        # mouse movements
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod ALT, mouse:272, resizewindow"
      ];

      bindd = [
        "$mod, SPACE, Launch apps, exec, nixcfg-launch-walker"

        "$mod, RETURN, Terminal, exec, $terminal --working-directory=\"$(nixcfg-cmd-terminal-cwd)\""
        "$mod, E, File manager, exec, uwsm app -- nautilus --new-window"
        "$mod, B, Browser, exec, $browser"
        "$mod SHIFT, B, Browser (private), exec, $browser --private"
        "$mod SHIFT, M, Music, exec, nixcfg-launch-or-focus spotify"
        "$mod SHIFT, N, Editor, exec, uwsm app -- zeditor"
        "$mod SHIFT, T, Activity, exec, $terminal -e btop"
        "$mod SHIFT, slash, Passwords, exec, uwsm app -- bitwarden-desktop"

        # Control tiling
        "$mod, T, Toggle floating, togglefloating,"
        "$mod, F, Force full screen, fullscreen, 0"
        "$mod, CTRL, F, Tiled full screen, fullscreenstate, 0 2"
        "$mod, ALT, F, Full width, fullscreen, 1"

        # Move focus with SUPER + arrow keys
        "$mod, LEFT, Move focus left, movefocus, l"
        "$mod, RIGHT, Move focus right, movefocus, r"
        "$mod, UP, Move focus up, movefocus, u"
        "$mod, DOWN, Move focus down, movefocus, d"

        # Switch workspaces with SUPER + [0-9]
        "$mod code:10, Switch to workspace 1, workspace, 1"
        "$mod code:11, Switch to workspace 2, workspace, 2"
        "$mod code:12, Switch to workspace 3, workspace, 3"
        "$mod code:13, Switch to workspace 4, workspace, 4"
        "$mod code:14, Switch to workspace 5, workspace, 5"
        "$mod code:15, Switch to workspace 6, workspace, 6"
        "$mod code:16, Switch to workspace 7, workspace, 7"
        "$mod code:17, Switch to workspace 8, workspace, 8"
        "$mod code:18, Switch to workspace 9, workspace, 9"
        "$mod code:19, Switch to workspace 10, workspace, 10"

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

        #"CONTROL SHIFT, V, Clipboard, exec, uwsm app -- walker --modules=clipboard"
        #"$mod SHIFT, O, Office applications, exec, systemctl --user start work.target"
        #"$mod SHIFT ALT, O, Close office applications, exec, systemctl --user stop work.target"
      ];
    };
  };
}

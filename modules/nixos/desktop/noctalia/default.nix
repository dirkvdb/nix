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
  inherit (config.lib.stylix) colors;
  mkUserHome = mkHome user.name;

  # stylix's base16 colors don't include the leading "#"; Noctalia's palette
  # JSON requires it.
  hex = c: "#${c}";

  # Darkens a "#rrggbb" color by scaling each channel toward black. Used to
  # derive Noctalia's secondary accent (e.g. inactive workspace pills) from
  # the primary accent, instead of pulling in an unrelated stylix color.
  darken =
    amount: color:
    let
      h = lib.removePrefix "#" color;
      toChannel = s: builtins.floor ((lib.fromHexString s) * (1 - amount));
      toHex = n: lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString n));
      r = toChannel (lib.substring 0 2 h);
      g = toChannel (lib.substring 2 2 h);
      b = toChannel (lib.substring 4 2 h);
    in
    "#" + toHex r + toHex g + toHex b;

  wallpapersDir = ../../../common/theme/wallpapers;

  # See https://docs.noctalia.dev/v5/getting-started/nixos/ for the schema.
  noctaliaSettings = {
    bar.default = {
      center = [ ];
      end = [
        "cpu"
        "tray"
        "notifications"
        "clipboard"
        "network"
        "bluetooth"
        "volume"
        "brightness"
        "battery"
        "control-center"
        "session"
      ];
      margin_ends = 0;
      radius = 0;
      shadow = false;
      thickness = 33;
      start = [
        "launcher"
        "workspaces"
        "spacer_2"
        "clock"
        "cat"
      ];
    };

    battery.warning_threshold = 5;
    brightness.enable_ddcutil = config.local.system.display.brightnesscontrol.enable or false;

    calendar = {
      enabled = true;
      account.personal_google = {
        name = "Google Calendar";
        type = "google";
      };
    };

    control_center.hidden_tabs = [
      "media"
      "screen-time"
    ];

    desktop_widgets = {
      enabled = false;
      schema_version = 2;
      widget_order = [ ];
      grid = {
        cell_size = 16;
        major_interval = 4;
        visible = true;
      };
      widget = { };
    };

    location.address = "Lommel, Belgium";

    lockscreen.fingerprint = false;

    lockscreen_widgets = {
      enabled = false;
      schema_version = 2;
      widget_order = [ "lockscreen-login-box@eDP-1" ];
      grid = {
        cell_size = 16;
        major_interval = 4;
        visible = true;
      };
      widget."lockscreen-login-box@eDP-1" = {
        box_height = 70.0;
        box_width = 400.0;
        cx = 756.0;
        cy = 863.0;
        output = "eDP-1";
        rotation = 0.0;
        type = "login_box";
        settings = {
          background_color = "surface_variant";
          background_opacity = 0.88;
          background_radius = 12.0;
          center_password_text = false;
          input_opacity = 1.0;
          input_radius = 6.0;
          show_caps_lock = true;
          show_keyboard_layout = true;
          show_login_button = true;
          show_password_hint = true;
        };
      };
    };

    plugins.enabled = [ ];

    # Shorten NetworkManager connection status toasts (connected/disconnected)
    # and KeePassXC popups (entry copied to clipboard, database locked, ...) to
    # 2s instead of the default toast duration.
    notification.filter.network = {
      enabled = true;
      match = "NetworkManager";
      override_duration = 2000;
    };
    notification.filter.keepassxc = {
      enabled = true;
      match = "KeePassXC";
      override_duration = 2000;
      save_history = false;
    };

    shell = {
      animation.speed = 3.0;
      panel = {
        control_center_position = "top_right";
        open_near_click_control_center = true;
        session_placement = "floating";
        session_position = "center";
      };
      session.actions = [
        {
          action = "lock";
          countdown_seconds = 0.0;
          enabled = true;
          shortcut = "1";
          variant = "default";
        }
        {
          action = "logout";
          countdown_seconds = 0.0;
          enabled = true;
          shortcut = "2";
          variant = "default";
        }
        {
          action = "lock_and_suspend";
          countdown_seconds = 0.0;
          enabled = false;
          shortcut = "3";
          variant = "default";
        }
        {
          action = "reboot";
          countdown_seconds = 0.0;
          enabled = true;
          shortcut = "4";
          variant = "default";
        }
        {
          action = "shutdown";
          countdown_seconds = 0.0;
          enabled = true;
          shortcut = "5";
          variant = "destructive";
        }
      ];
    };

    theme = {
      custom_palette = "stylix";
      source = "custom";
    };

    wallpaper = {
      automation.enabled = true;
      directory = "${wallpapersDir}";
      default.path = "${config.stylix.image}";
    };

    widget = {
      battery.show_label = false;
      brightness.enabled = false;
      clipboard.enabled = false;
      "control-center".enabled = false;
      cpu = {
        display = "graph";
        show_label = false;
      };
      launcher.glyph = "snowflake";
      media.enabled = false;
      network.show_label = false;
      notifications.enabled = false;
      spacer_2 = {
        interactive = false;
        length = 15;
        type = "spacer";
      };
      volume.show_label = false;
      workspaces = {
        active_pill_size = 1.75;
      };
      # Append month + day-of-month after the time (e.g. "14:32  July 20").
      clock.format = "{:%H:%M  %e %B}";
    };
  };

  noctaliaConfigToml = (pkgs.formats.toml { }).generate "config.toml" noctaliaSettings;

  # Noctalia palette generated from the active stylix base16 scheme, so
  # switching local.theme.preset automatically updates Noctalia's colors.
  # See https://docs.noctalia.dev/v5/theming/palette/ for the role/field mapping.
  noctaliaPaletteName = "stylix";
  noctaliaPalette = {
    dark = {
      mPrimary = hex colors.base0D;
      mOnPrimary = hex colors.base00;
      # Darker shade of the primary accent, instead of an unrelated stylix
      # color (avoids e.g. inactive workspace pills rendering as green).
      mSecondary = darken 0.5 (hex colors.base0D);
      mOnSecondary = hex colors.base00;
      # warm shade (matches mHover), instead of an unrelated
      # stylix color (avoids e.g. sidebar hover highlights rendering as teal).
      mTertiary = "#dbc688";
      mOnTertiary = hex colors.base00;
      mError = hex colors.base08;
      mOnError = hex colors.base00;
      mSurface = hex colors.base00;
      mOnSurface = hex colors.base05;
      mSurfaceVariant = hex colors.base01;
      mOnSurfaceVariant = hex colors.base04;
      mOutline = hex colors.base03;
      mShadow = hex colors.base00;
      mHover = "#dbc688";
      mOnHover = hex colors.base00;
      terminal = {
        background = hex colors.base00;
        foreground = hex colors.base05;
        cursor = hex colors.base05;
        cursorText = hex colors.base00;
        selectionBg = hex colors.base02;
        selectionFg = hex colors.base05;
        normal = {
          black = hex colors.base00;
          red = hex colors.base08;
          green = hex colors.base0B;
          yellow = hex colors.base0A;
          blue = hex colors.base0D;
          magenta = hex colors.base0E;
          cyan = hex colors.base0C;
          white = hex colors.base05;
        };
        bright = {
          black = hex colors.base03;
          red = hex colors.base08;
          green = hex colors.base0B;
          yellow = hex colors.base0A;
          blue = hex colors.base0D;
          magenta = hex colors.base0E;
          cyan = hex colors.base0C;
          white = hex colors.base07;
        };
      };
    };
  };
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

      # Noctalia's own settings (bar layout, theme, session actions, ...).
      xdg.configFile."noctalia/config.toml".source = noctaliaConfigToml;

      # Upstream ships no fish completions for the noctalia CLI; provide a
      # hand-maintained one (msg subcommands are queried live from the
      # running instance since that list changes across releases).
      xdg.configFile."fish/completions/noctalia.fish" = lib.mkIf (
        user.shell.package == pkgs.fish || config.local.system.shell.fish.enable
      ) { source = ./completions.fish; };

      # Custom palette generated from the active stylix colors; selected via
      # [theme] source = "custom", custom_palette = "stylix" in config.toml.
      xdg.configFile."noctalia/palettes/${noctaliaPaletteName}.json".text = builtins.toJSON noctaliaPalette;

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

{
  lib,
  pkgs,
  config,
  inputs,
  mkHome,
  ...
}:
let
  cfg = config.local.desktop.noctalia;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable or false;
  isHeadless = config.local.headless or false;
  isHyprlandEnabled = config.local.desktop.hyprland.enable or false;
  inherit (config.local) theme user;
  inherit (config.lib.stylix) colors;
  mkUserHome = mkHome user.name;

  # Set bar thickness based on hostname (33 for macbook-pro due to the notch, 26 for others).
  # The notch also obstructs the bar's center area, so the clock stays in
  # the start section there instead of being centered.
  hostname = config.local.system.network.hostname or "";
  hasNotch = hostname == "macbook-pro";
  barThickness = if hasNotch then 33 else 26;

  # The Outlook calendar (ICS feed) is only relevant on the dell-workstation.
  isDellWorkstation = hostname == "dell-workstation";

  voxtypeEnabled = config.local.apps.voxtype.enable or false;
  devUtilsEnabled = config.local.system.utils.enable && config.local.system.utils.dev;

  # stylix's base16 colors don't include the leading "#"; Noctalia's palette
  # JSON requires it.
  hex = c: "#${c}";

  # Default (non-emphasized) text/icon color for Noctalia's shell surfaces.
  # Kept cooler and more muted than the accent so ordinary bar/panel content
  # doesn't compete with actual highlights.
  noctaliaDefaultText = theme.uiTextColor;

  # Warm highlight color for Noctalia's high-emphasis UI roles (primary
  # accent, hover state). Matches the shared theme accent color used by GTK,
  # waybar, and hyprland borders, so highlighted text looks consistent across
  # apps and the shell.
  noctaliaHighlight = theme.uiAccentColor;

  wallpapersDir = ../../../common/theme/wallpapers;

  # use storage key mechanism instead of secrets store, because noctalia starts before
  # the secrets store is unlocked (it waits for the systray), and causes a
  noctaliaStorageKeyFile = config.sops.secrets.noctalia_storage_key.path;

  # See https://docs.noctalia.dev/v5/getting-started/nixos/ for the schema.
  noctaliaSettings = {
    storage = {
      key_source = "file";
      key_file = noctaliaStorageKeyFile;
    };

    brightness = {
      sync_all_monitors = true;
    };

    plugin_settings = lib.optionalAttrs devUtilsEnabled {
      "felipeartur/ai-usagebar" = {
        panel_open_near_click = true;
      };
    };

    bar.default = {
      font_family = config.stylix.fonts.sansSerif.name;
      center = lib.optionals (!hasNotch) [ "clock" ] ++ [ "notifications" ] ++ lib.optionals voxtypeEnabled [ "status" ];
      end = [
        "cpu"
        "ram"
        "sysmon"
        "tray"
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
      thickness = barThickness;
      start = [
        "launcher"
        "workspaces"
        "spacer_2"
      ] ++ lib.optionals devUtilsEnabled [
        "bar_2"
        "bar"
      ] ++ lib.optionals hasNotch [ "clock" ];
    };

    battery.warning_threshold = 5;
    brightness.enable_ddcutil = config.local.system.display.brightnesscontrol.enable or false;

    calendar = {
      enabled = true;
      account =
        {
          personal_google = {
            name = "Google Calendar";
            type = "google";
          };
        }
        // lib.optionalAttrs isDellWorkstation {
          vito_outlook = {
            color = "tertiary";
            name = "Vito";
            server_url = config.sops.placeholder.vito_outlook_ics_url;
            type = "ics";
          };
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

    idle = {
      behavior_order = [
        "screen-off"
        "lock"
        "lock-and-suspend"
      ];
      pre_action_fade_seconds = 5;
      behavior.lock = {
        action = "lock";
        enabled = false;
        timeout = 3600.0;
      };
      behavior."lock-and-suspend" = {
        action = "lock_and_suspend";
        enabled = false;
        timeout = 900.0;
      };
      behavior."screen-off" = {
        action = "screen_off";
        enabled = true;
        timeout = 600.0;
      };
    };

    location.address = "Lommel, Belgium";

    lockscreen.fingerprint = cfg.fingerprint.enable;

    lockscreen_widgets = {
      enabled = false;
    };

    nightlight = {
      enabled = true;
      temperature_night = 4500;
    };

    plugins.enabled = lib.optionals voxtypeEnabled [ "gabedunn/voxtype" ] ++ lib.optionals devUtilsEnabled [ "felipeartur/ai-usagebar" ];

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
    notification.filter.satty = {
      allow_permanent = true;
      enabled = true;
      match = "satty";
      play_sound = false;
      save_history = false;
      show_toast = false;
    };

    shell = {
      animation.speed = 3.0;
      app_icon_color = "primary";
      app_icon_colorize = false;
      launcher.dmenu.entry.ssh = {
        command = "awk '/^Host /{print $2}' ~/.ssh/config"; # one candidate per stdout line
        exec = "${lib.getExe pkgs.ghostty} -e ssh {selection}"; # {selection} = the chosen line; run detached
        prefix = "ssh"; # trigger word (composed with provider_prefix -> "/ssh"); empty = global only
        glyph = "server"; # optional Tabler glyph shared by every result
        global = false; # true = also surface in unprefixed search
      };
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
          enabled = true;
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
      ram = {
        stat = "ram_pct";
      };

      sysmon = {
        stat = "disk_used_pct";
      };

      battery = {
        show_label = false;
      };

      brightness = {
        enabled = false;
      };
      clipboard = {
        enabled = false;
      };
      "control-center" = {
        enabled = false;
      };
      cpu = {
        visualization = "graph";
        show_glyph = false;
        actions = {
          right = "exec ghostty -e btop";
        };
      };
      launcher.glyph = "snowflake";
      media.enabled = false;
      network = {
        show_label = false;
      };
      notifications = {
        enabled = true;
        hide_when_no_unread = true;
      };
      spacer_2 = {
        interactive = false;
        length = 15;
        type = "spacer";
      };
      tray.app_icon_colorize = true;
      volume = {
        show_label = false;
      };
      workspaces = {
        active_pill_size = 1.5;
      };
      # Append month + day-of-month after the time (e.g. "14:32  July 20").
      clock.format = "{:%H:%M  %e %B}";
    }
    // lib.optionalAttrs voxtypeEnabled {
      status.type = "gabedunn/voxtype:status";
    }
    // lib.optionalAttrs devUtilsEnabled {
      bar = {
        extras = "none";
        type = "felipeartur/ai-usagebar:bar";
        vendor = "openai";
      };
      bar_2 = {
        extras = "none";
        type = "felipeartur/ai-usagebar:bar";
        vendor = "copilot";
      };
    };
  };

  noctaliaConfigToml = (pkgs.formats.toml { }).generate "config.toml" noctaliaSettings;

  # Noctalia palette generated from the active stylix base16 scheme, so
  # switching local.theme.preset automatically updates Noctalia's colors.
  # See https://docs.noctalia.dev/v5/theming/palette/ for the role/field mapping.
  noctaliaPaletteName = "stylix";
  noctaliaPalette = {
    dark = {
      # Keep ordinary shell chrome neutral. The primary highlight matches the
      # shared theme accent color; semantic base08-0F colors remain reserved
      # for statuses and ANSI.
      mPrimary = noctaliaHighlight;
      mOnPrimary = hex colors.base00;
      mSecondary = hex colors.base04;
      mOnSecondary = hex colors.base00;
      # Noctalia uses the tertiary accent for warning-style UI.
      mTertiary = hex colors.base0A;
      mOnTertiary = hex colors.base00;
      mError = hex colors.base08;
      mOnError = hex colors.base00;
      mSurface = hex colors.base00;
      mOnSurface = noctaliaDefaultText;
      mSurfaceVariant = hex colors.base01;
      mOnSurfaceVariant = hex colors.base04;
      mOutline = hex colors.base03;
      mShadow = hex colors.base00;
      mHover = hex colors.base02;
      mOnHover = noctaliaHighlight;
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
          blue = "#91a7b5";
          magenta = hex colors.base0E;
          cyan = hex colors.base0C;
          white = hex colors.base05;
        };
        bright = {
          black = hex colors.base03;
          red = hex colors.base08;
          green = hex colors.base0B;
          yellow = hex colors.base0A;
          blue = "#91a7b5";
          magenta = hex colors.base0E;
          cyan = hex colors.base0C;
          white = hex colors.base07;
        };
      };
    };

    # Light variant — Rosé Pine Dawn cream surface, biscuit primary accent,
    # all text/chrome from the everforest warm-gray scale (no purple).
    light = {
      # Dark charcoal primary (everforest base00) — scheme-aware, no hardcoded hex.
      mPrimary = hex colors.base00;
      mOnPrimary = "#faf4ed";           # cream text on dark charcoal
      mSecondary = hex colors.base04;   # everforest warm tan
      mOnSecondary = hex colors.base01; # everforest dark warm gray
      mTertiary = hex colors.base0A;    # everforest warm yellow
      mOnTertiary = hex colors.base01;
      mError = hex colors.base08;
      mOnError = hex colors.base01;
      mSurface = "#faf4ed";              # Rosé Pine Dawn base — warm cream
      mOnSurface = hex colors.base01;    # everforest #2d3035 — dark warm gray
      # Warm stone-gray panels: same temperature as the cream bg, no blue cast.
      mSurfaceVariant = "#e5e1db";
      mOnSurfaceVariant = hex colors.base03; # everforest #67645f — warm muted
      mOutline = hex colors.base04;      # everforest #948b7e — warm tan border
      mShadow = hex colors.base03;       # everforest #67645f — warm shadow
      mHover = "#d5cfc7";               # slightly darker warm gray
      mOnHover = hex colors.base01;
      terminal = {
        background = "#faf4ed";
        foreground = hex colors.base01;  # dark warm gray
        cursor = hex colors.base01;
        cursorText = "#faf4ed";
        selectionBg = "#d5cfc7";
        selectionFg = hex colors.base01;
        normal = {
          black = hex colors.base01;     # dark warm gray
          red = hex colors.base08;
          green = hex colors.base0B;
          yellow = hex colors.base0A;
          blue = "#7d9aaa";             # desaturated slate-teal, no purple
          magenta = hex colors.base0E;
          cyan = hex colors.base0C;
          white = "#e5e1db";            # warm stone — matches panel bg
        };
        bright = {
          black = hex colors.base03;     # everforest #67645f — warm muted
          red = hex colors.base08;
          green = hex colors.base0B;
          yellow = hex colors.base0A;
          blue = "#7d9aaa";
          magenta = hex colors.base0E;
          cyan = hex colors.base0C;
          white = "#faf4ed";            # cream — brightest white
        };
      };
    };
  };
in
{
  options.local.desktop.noctalia = {
    enable = lib.mkEnableOption "Noctalia v5 (beta) desktop shell";

    fingerprint.enable = lib.mkEnableOption ''
      fingerprint unlock on the Noctalia lock screen. Noctalia talks to fprintd
      directly over D-Bus (net.reactivated.Fprint), so this only needs
      services.fprintd enabled; no PAM service configuration is required.
      Enroll fingerprints with `fprintd-enroll` after switching.
    '';
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
        {
          assertion = !cfg.enable || (config.local.apps.sops.enable or false);
          message = ''
            local.desktop.noctalia.enable requires local.apps.sops.enable, since
            Noctalia's encrypted storage master key (clipboard history, calendar
            event cache) is provisioned via the noctalia_storage_key sops secret.
          '';
        }
      ];
    }
    (lib.mkIf cfg.enable {
      # Noctalia is a shell/bar; it still needs a compositor underneath.
      # Only takes effect if a host hasn't already set this explicitly.
      local.desktop.hyprland.enable = lib.mkDefault true;

      services.fprintd.enable = lib.mkIf cfg.fingerprint.enable true;

      # Noctalia's lockscreen authenticates passwords against the "login" PAM
      # service while driving the fingerprint reader itself directly over
      # D-Bus (net.reactivated.Fprint); see fingerprint.enable above. PAM's
      # fprintAuth defaults to services.fprintd.enable, which would also
      # insert pam_fprintd.so into that same "login" service. Since noctalia
      # already holds the fprintd device claim, that second, PAM-driven
      # verification attempt can't run and just blocks password auth for its
      # ~30s timeout before falling through to pam_unix. Disable it here so
      # password entry stays instant.
      # https://github.com/noctalia-dev/noctalia/issues/3277
      security.pam.services.login.fprintAuth = lib.mkIf cfg.fingerprint.enable false;

      programs.noctalia = {
        enable = true;
        package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./trayicon.patch
            ./DelayCalendarInit.patch
          ];
          mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dnative_optimizations=true" ];
          NIX_ENFORCE_NO_NATIVE = false;
        });

        # Starts noctalia automatically after login via a systemd user
        # service, tied to the same graphical-session.target that UWSM
        # activates once Hyprland is up.
        systemd.enable = true;

        # Enables NetworkManager, Bluetooth, UPower, and a power profile service.
        recommendedServices.enable = true;
      };

      # Renders config.toml with the vito_outlook calendar's ICS URL secret
      # substituted in, so the plaintext URL never lands in the world-readable
      # Nix store; only the placeholder token does.
      sops.templates."noctalia-config" = {
        path = "/home/${user.name}/.config/noctalia/config.toml";
        owner = user.name;
        mode = "0400";
        content = builtins.readFile noctaliaConfigToml;
      };
    })
    (lib.mkIf (cfg.enable && isLinux && isDesktop && !isHeadless && isHyprlandEnabled) (mkUserHome {
      # Hyprland keybindings specific to this shell (Noctalia power menu).
      xdg.configFile."hypr/bindings-noctalia.lua".source = ./bindings.lua;

      # Noctalia's own settings (bar layout, theme, session actions, ...) are
      # rendered via sops.templates."noctalia-config" above instead of being
      # symlinked directly here, since the calendar section can contain a
      # secret (ICS feed URL).

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

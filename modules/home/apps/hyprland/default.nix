{
  pkgs,
  config,
  lib,
  inputs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.local) theme;
  inherit (config.lib.stylix) colors;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable;
  isHyprlandEnabled = config.local.desktop.hyprland.enable or false;
  isWaybarEnabled = config.local.desktop.waybar.enable or false;
  isNoctaliaEnabled = config.local.desktop.noctalia.enable or false;
  sopsEnabled = config.local.apps.sops.enable or false;
  devWorkspaceGapSize = config.local.desktop.hyprland.devWorkspaceGapSize or 0;
  mkUserHome = mkHome user.name;

  # Border colors used in general and group config sections
  activeBorderColor = "rgb(${lib.strings.removePrefix "#" theme.uiAccentColor})";
  inactiveBorderColor = "rgba(${lib.strings.removePrefix "#" colors.base04}aa)";

  # Auto-start applications launched via hl.on("hyprland.start", ...)
  startupCommands = [
    "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"
    "wl-paste --watch --primary wl-copy"
    # NOTE: must be "regular" (not "both"). Persisting the PRIMARY
    # selection causes wl-clip-persist to instantly reclaim ownership of it
    # whenever a GTK app creates a text selection (mouse-drag or
    # Shift+Arrow), which makes GTK immediately clear the visible
    # highlight since GtkText/GtkEntry ties selection rendering to actually
    # owning the Wayland PRIMARY selection. Known upstream bug, unresolved:
    # https://github.com/Linus789/wl-clip-persist/issues/3
    "wl-clip-persist --clipboard regular"
  ]
  ++ lib.optionals config.local.services.sunshine.enable [
    "hyprctl output create headless SUNSHINE && systemctl --user restart sunshine.service"
  ];
in
{
  imports = [
    ./bindings.nix
    ./hyprexpose.nix
  ];

  config = lib.mkIf (isLinux && isDesktop && isHyprlandEnabled) (mkUserHome {
    stylix.targets.hyprland.enable = false;

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
        ${lib.optionalString isWaybarEnabled ''require("bindings-waybar")''}
        ${lib.optionalString isNoctaliaEnabled ''require("bindings-noctalia")''}
        require("monitors")
        ${lib.optionalString (devWorkspaceGapSize > 0) ''
          hl.workspace_rule({ workspace = "3", gaps_in = ${toString devWorkspaceGapSize}, gaps_out = ${toString devWorkspaceGapSize} })
        ''}
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

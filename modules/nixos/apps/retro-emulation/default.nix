{
  lib,
  config,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.apps.retro-emulation;

  esDe = pkgs.es-de;

  eden = unstablePkgs.eden.overrideAttrs (old: {
    # Build with -march=native for maximum performance on this machine
    NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " -march=native";
  });

  edenWrapped = unstablePkgs.symlinkJoin {
    name = "eden-wrapped";
    paths = [ eden ];

    nativeBuildInputs = [ unstablePkgs.makeWrapper ];

    postBuild = ''
      for bin in eden eden-cli eden-room; do
        if [ -f "$out/bin/$bin" ]; then
          wrapProgram "$out/bin/$bin" \
            --set QT_STYLE_OVERRIDE Fusion
        fi
      done

      desktopFile="$out/share/applications/dev.eden_emu.eden.desktop"
      if [ -f "$desktopFile" ]; then
        if [ -L "$desktopFile" ]; then
          rm "$desktopFile"
          cp "${eden}/share/applications/dev.eden_emu.eden.desktop" "$desktopFile"
          chmod u+w "$desktopFile"
        fi

        sed -i "s|^Exec=.*|Exec=$out/bin/eden %f|" "$desktopFile"
        sed -i "s|^TryExec=.*|TryExec=$out/bin/eden|" "$desktopFile"
      fi
    '';
  };
  dolphinEmuWrapped = unstablePkgs.symlinkJoin {
    name = "dolphin-emu-wrapped";
    paths = [ unstablePkgs.dolphin-emu ];

    nativeBuildInputs = [ unstablePkgs.makeWrapper ];

    postBuild = ''
      for bin in dolphin-emu dolphin-emu-nogui dolphin-tool; do
        if [ -f "$out/bin/$bin" ]; then
          wrapProgram "$out/bin/$bin" \
            --set QT_STYLE_OVERRIDE Fusion \
            --set QT_SCALE_FACTOR 1.75
        fi
      done
    '';
  };
in
{
  options.local.apps.retro-emulation = {
    enable = lib.mkEnableOption "retro emulation stack";

    fladder = {
      enable = lib.mkEnableOption "Fladder Jellyfin client (also added as ES-DE desktop entry)";
    };

    moonlight = {
      enable = lib.mkEnableOption "Moonlight game streaming client (also added as ES-DE desktop entry)";
      sunshineHost = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Hostname or IP of the Sunshine server to stream from.";
      };
      platform = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Platform name used by ES-DE for scraping metadata (e.g. 'switch', 'pc'). Must match a ScreenScraper/TheGamesDB platform identifier.";
      };
      apps = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Display name for the app in ES-DE.";
              };
              sunshineApp = lib.mkOption {
                type = lib.types.str;
                default = "";
                description = "Name of the app as registered in Sunshine. Defaults to the display name.";
              };
            };
          }
        );
        default = [ ];
        description = "List of Sunshine apps to make available as a custom ES-DE system.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    local.apps.retro-emulation.fladder.enable = lib.mkDefault true;
    local.apps.retro-emulation.moonlight.enable = lib.mkDefault true;

    boot.kernelModules = [ "uhid" ];

    users.groups.uinput = { };
    users.users.${config.local.user.name}.extraGroups = [
      "input"
      "uinput"
    ];
    services.udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="uinput"
      KERNEL=="uhid", MODE="0660", GROUP="input"
    '';

    environment.systemPackages =
      lib.optionals cfg.fladder.enable [
        unstablePkgs.fladder
      ]
      ++ [
        pkgs.ffmpeg
        esDe
        edenWrapped
        (unstablePkgs.retroarch.withCores (
          cores:
          with cores;
          [
            snes9x
            dolphin
            beetle-psx-hw
          ]
          ++ lib.optionals (!pkgs.stdenv.hostPlatform.isAarch64) [
            ppsspp
          ]
        ))
        unstablePkgs.retroarch-joypad-autoconfig
        dolphinEmuWrapped
      ]
      ++ lib.optionals (!pkgs.stdenv.hostPlatform.isAarch64) [
        unstablePkgs.cemu
        unstablePkgs.ppsspp
      ];

    services.udev.packages = [ edenWrapped ];
  };
}

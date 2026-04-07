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
    version = "0.2.0-rc2";
    src = old.src.override {
      tag = "v0.2.0-rc2";
      hash = "sha256-keLkB5qeQch+tM2J6zVh9oQGhP5TuxItqrZRN24apJw=";
    };
    # Drop the aarch64-disable-fastmem patch - it no longer applies to 0.2.0-rc2
    # and is irrelevant on x86_64 anyway
    patches = [ ];
    # 0.2.0-rc2 added a dependency on Qt6Charts
    buildInputs = old.buildInputs ++ [ unstablePkgs.qt6.qtcharts ];
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
  };

  config = lib.mkIf cfg.enable {
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

    services.sunshine = {
      enable = true;
      autoStart = true;

      openFirewall = true;

      settings = {
        fps = 60;
        min_fps_factor = 1;
        channels = 2;
        output_name = 1;
        encoder = "vaapi";
      };

      applications.apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
        }
        {
          name = "Desktop 2160p";
          image-path = "desktop.png";
          prep-cmd = [
            {
              do = "hyprctl keyword monitor ,3840x2160@60,auto,1.66666667";
              undo = "hyprctl keyword monitor ,preferred,auto,${toString config.local.desktop.displayScale}";
            }
          ];
        }
        {
          name = "ES-DE";
          detached = [ "${esDe}/bin/es-de" ];
          image-path = "${./esde.png}";
          prep-cmd = [
            {
              do = "hyprctl keyword monitor ,3840x2160@60,auto,1.4";
              undo = "hyprctl keyword monitor ,preferred,auto,${toString config.local.desktop.displayScale}";
            }
          ];
          auto-detach = "true";
        }
      ];
    };

    environment.systemPackages = [
      pkgs.ffmpeg
      esDe
      edenWrapped
      (unstablePkgs.retroarch.withCores (
        cores: with cores; [
          snes9x
          ppsspp
          dolphin
          beetle-psx-hw
        ]
      ))
      unstablePkgs.retroarch-joypad-autoconfig
      unstablePkgs.cemu
      dolphinEmuWrapped
      unstablePkgs.ppsspp
    ];

    services.udev.packages = [ edenWrapped ];
  };
}

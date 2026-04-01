{
  lib,
  config,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.apps.retro-emulation;
  esDe = unstablePkgs.callPackage ../../../../pkgs/es-de { };

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
      for bin in eden eden-room; do
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
    users.groups.uinput = { };
    users.users.${config.local.user.name}.extraGroups = [ "uinput" ];
    services.udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="uinput"
    '';

    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;

      applications.apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
        }
        {
          name = "ES-DE";
          detached = [ "sudo -u ${config.local.user.name} ${esDe}/bin/es-de" ];
          image-path = "${./esde.png}";
          exclude-global-prep-cmd = "false";
          auto-detach = "true";
        }
      ];
    };

    environment.systemPackages = [
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

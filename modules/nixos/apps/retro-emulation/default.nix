{
  lib,
  config,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.apps.retro-emulation;
  esDe = unstablePkgs.callPackage ../../../../pkgs/es-de { };

  edenWrapped = unstablePkgs.symlinkJoin {
    name = "eden-wrapped";
    paths = [ unstablePkgs.eden ];

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
          cp "${unstablePkgs.eden}/share/applications/dev.eden_emu.eden.desktop" "$desktopFile"
          chmod u+w "$desktopFile"
        fi

        sed -i "s|^Exec=.*|Exec=$out/bin/eden %f|" "$desktopFile"
        sed -i "s|^TryExec=.*|TryExec=$out/bin/eden|" "$desktopFile"
      fi
    '';
  };
in
{
  options.local.apps.retro-emulation = {
    enable = lib.mkEnableOption "retro emulation stack";
  };

  config = lib.mkIf cfg.enable {
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
      unstablePkgs.ppsspp
    ];

    services.udev.packages = [ edenWrapped ];
  };
}

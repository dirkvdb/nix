{
  lib,
  config,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.apps.eden;

  edenWrapped = pkgs.symlinkJoin {
    name = "eden-wrapped";
    paths = [ unstablePkgs.eden ];

    nativeBuildInputs = [ pkgs.makeWrapper ];

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
  options.local.apps.eden = {
    enable = lib.mkEnableOption "Eden emulator";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ edenWrapped ];

    services.udev.packages = [ edenWrapped ];
  };
}

{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.vlc;
  vlcWrapped = pkgs.symlinkJoin {
    name = "vlc-wrapped";
    paths = [
      pkgs.vlc
    ];

    buildInputs = [
      pkgs.makeWrapper
    ];

    postBuild = ''
      wrapProgram "$out/bin/vlc" --set QT_SCALE_FACTOR 2.0

      if [ -f "$out/share/applications/vlc.desktop" ]; then
        if [ -L "$out/share/applications/vlc.desktop" ]; then
          rm "$out/share/applications/vlc.desktop"
          cp "${pkgs.vlc}/share/applications/vlc.desktop" "$out/share/applications/vlc.desktop"
          chmod u+w "$out/share/applications/vlc.desktop"
        fi
        sed -i "s|^Exec=[^ ]*|Exec=$out/bin/vlc|" "$out/share/applications/vlc.desktop"
        sed -i "s|^TryExec=.*|TryExec=$out/bin/vlc|" "$out/share/applications/vlc.desktop"
      fi
    '';
  };
in
{
  options.local.apps.vlc = {
    enable = lib.mkEnableOption "vlc";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      vlcWrapped
    ];
  };
}

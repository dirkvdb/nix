{
  lib,
  pkgs,
  config,
  inputs,
  mkHome,
  ...
}:
let
  cfg = config.local.apps.localsend;
  inherit (config.local) user;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.localsend = {
    enable = lib.mkEnableOption "Install LocalSend (cross platform AirDrop alternative)";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.localsend = {
          enable = true;
          openFirewall = true;
        };
      }

      (mkUserHome {
        home.activation.configureLocalSend =
          inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ]
            ''
              preferences="$HOME/.local/share/org.localsend.localsend_app/shared_preferences.json"
              mkdir -p "$(dirname "$preferences")"

              if [ -f "$preferences" ]; then
                ${pkgs.jq}/bin/jq \
                  '. + {"flutter.ls_quick_save": true, "flutter.ls_auto_finish": true}' \
                  "$preferences" > "$preferences.tmp"
              else
                ${pkgs.jq}/bin/jq -n \
                  '{"flutter.ls_quick_save": true, "flutter.ls_auto_finish": true}' \
                  > "$preferences.tmp"
              fi

              mv "$preferences.tmp" "$preferences"
              rm -f "$HOME/.config/autostart/localsend_app.desktop"
            '';
      })
    ]
  );
}

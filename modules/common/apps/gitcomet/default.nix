{
  config,
  lib,
  pkgs,
  unstablePkgs,
  mkHome,
  ...
}:
let
  cfg = config.local.apps.gitcomet;
  jsonFormat = pkgs.formats.json { };
  themeFamily = builtins.fromJSON (builtins.readFile ../../../../configs/themes/charcoal-grove.json);
  theme = jsonFormat.generate "gitcomet-charcoal-grove.json" (
    import ../../../../configs/themes/zed-to-gitcomet.nix themeFamily
  );
  settings = jsonFormat.generate "gitcomet-default-settings.json" (
    builtins.fromJSON (builtins.readFile ./defaults.json)
    // {
      ui_font_family = config.stylix.fonts.sansSerif.name;
      editor_font_family = config.stylix.fonts.monospace.name;
      external_code_editor = {
        kind = "detected";
        id = "zed";
        path = "/etc/profiles/per-user/${config.local.user.name}/bin/zeditor";
      };
    }
  );
  package =
    if pkgs.stdenv.isLinux then
      pkgs.symlinkJoin {
        name = "gitcomet-${unstablePkgs.gitcomet.version}";
        paths = [ unstablePkgs.gitcomet ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/gitcomet" --set GITCOMET_NO_DESKTOP_INSTALL 1
        '';
      }
    else
      unstablePkgs.gitcomet;
in
{
  options.local.apps.gitcomet = {
    enable = lib.mkEnableOption "GitComet Desktop" // {
      default = config.local.system.utils.dev && (config.local.desktop.enable or false);
    };

  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      { environment.systemPackages = [ package ]; }
      (mkHome config.local.user.name (
        { config, lib, ... }:
        let
          appDir =
            if pkgs.stdenv.isDarwin then
              "${config.home.homeDirectory}/Library/Application Support/gitcomet"
            else
              "${config.xdg.dataHome}/gitcomet";
          stateDir = if pkgs.stdenv.isDarwin then appDir else "${config.xdg.stateHome}/gitcomet";
        in
        {
          home.file."${appDir}/themes/charcoal-grove.json".source = theme;
          # GitComet writes session state here; copy instead of linking, like Flea.
          home.activation.gitcometSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg stateDir}
            run ${pkgs.coreutils}/bin/cp --remove-destination --no-preserve=mode ${settings} ${lib.escapeShellArg "${stateDir}/session.json"}
            run ${pkgs.coreutils}/bin/chmod 600 ${lib.escapeShellArg "${stateDir}/session.json"}
          '';
        }
      ))
    ]
  );
}

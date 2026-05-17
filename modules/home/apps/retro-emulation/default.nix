{
  lib,
  pkgs,
  config,
  unstablePkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.retro-emulation;
  moonlightCfg = config.local.apps.moonlight;
  mkUserHome = mkHome user.name;

  desktopEntries =
    lib.optionals cfg.fladder.enable [
      {
        name = "Fladder";
        exec = "${unstablePkgs.fladder}/bin/Fladder";
        categories = "AudioVideo;Video;";
      }
    ]
    ++ lib.optionals (cfg.moonlight.enable && moonlightCfg.enable) [
      {
        name = "Moonlight";
        exec = "${pkgs.moonlight-qt}/bin/moonlight";
        categories = "Game;";
      }
    ];

  desktopDir = pkgs.runCommand "es-de-desktop-apps" { } (
    ''
      mkdir -p $out
    ''
    + lib.concatMapStrings (entry: ''
      cat > $out/${entry.name}.desktop <<EOF
      [Desktop Entry]
      Type=Application
      Name=${entry.name}
      Exec=${entry.exec}
      Terminal=false
      Categories=${entry.categories}
      EOF
    '') desktopEntries
  );

  customSystemsXml = ''
    <?xml version="1.0"?>
    <systemList>
        <system>
            <name>desktop</name>
            <fullname>Desktop Applications</fullname>
            <path>${desktopDir}</path>
            <extension>.desktop</extension>
            <command label="Suspend ES-DE">%ENABLESHORTCUTS% %EMULATOR_OS-SHELL% %ROM%</command>
            <command label="Keep ES-DE running">%RUNINBACKGROUND% %ENABLESHORTCUTS% %EMULATOR_OS-SHELL% %ROM%</command>
            <platform>pcwindows</platform>
            <theme>desktop</theme>
        </system>
    </systemList>
  '';

  hasDesktopEntries = cfg.fladder.enable || (cfg.moonlight.enable && moonlightCfg.enable);
in
{
  config = lib.mkIf (cfg.enable && hasDesktopEntries) (mkUserHome {
    home.file."ES-DE/custom_systems/es_systems.xml".text = customSystemsXml;
  });
}

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

  # Moonlight streaming: create a launcher script for each Sunshine app
  hasMoonlightApps = cfg.moonlight.enable && moonlightCfg.enable && cfg.moonlight.apps != [ ];

  moonlightLaunchers = map (
    app:
    let
      appName = if app.sunshineApp != "" then app.sunshineApp else app.name;
    in
    pkgs.writeShellScript "moonlight-${lib.strings.sanitizeDerivationName app.name}.sh" ''
      exec ${pkgs.moonlight-qt}/bin/moonlight stream ${cfg.moonlight.sunshineHost} "${appName}"
    ''
  ) cfg.moonlight.apps;

  moonlightDir = pkgs.runCommand "es-de-moonlight-apps" { } (
    ''
      mkdir -p $out
    ''
    + lib.concatImapStrings (
      i: app:
      let
        launcher = builtins.elemAt moonlightLaunchers (i - 1);
      in
      ''
        cat > "$out/${app.name}.sh" <<EOF
        #!/bin/sh
        exec ${launcher}
        EOF
        chmod +x "$out/${app.name}.sh"
      ''
    ) cfg.moonlight.apps
  );

  hasDesktopEntries = cfg.fladder.enable || (cfg.moonlight.enable && moonlightCfg.enable);

  customSystemsXml = ''
    <?xml version="1.0"?>
    <systemList>
  ''
  + lib.optionalString hasDesktopEntries ''
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
  ''
  + lib.optionalString hasMoonlightApps ''
    <system>
        <name>moonlight</name>
        <fullname>Moonlight</fullname>
        <path>${moonlightDir}</path>
        <extension>.sh</extension>
        <command label="Suspend ES-DE">%ENABLESHORTCUTS% %EMULATOR_OS-SHELL% %ROM%</command>
        <command label="Keep ES-DE running">%RUNINBACKGROUND% %ENABLESHORTCUTS% %EMULATOR_OS-SHELL% %ROM%</command>
        <platform>${cfg.moonlight.platform}</platform>
        <theme>moonlight</theme>
    </system>
  ''
  + ''
    </systemList>
  '';

  hasAnySystems = hasDesktopEntries || hasMoonlightApps;
in
{
  config = lib.mkIf cfg.enable (
    mkUserHome (
      lib.optionalAttrs hasAnySystems {
        xdg.configFile."ES-DE/custom_systems/es_systems.xml".text = customSystemsXml;
      }
      // {
        xdg.configFile."eden/input/Moonlight.ini".source = ../../../nixos/services/sunshine/Moonlight.ini;
      }
    )
  );
}

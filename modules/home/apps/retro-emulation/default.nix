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
        <theme>switch</theme>
    </system>
  ''
  + ''
    </systemList>
  '';

  hasAnySystems = hasDesktopEntries || hasMoonlightApps;
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

  config = lib.mkIf cfg.enable (
    mkUserHome (
      lib.optionalAttrs hasAnySystems {
        home.file."ES-DE/custom_systems/es_systems.xml".text = customSystemsXml;
      }
      // {
        xdg.configFile."eden/input/Moonlight.ini".source = ../../../nixos/services/sunshine/Moonlight.ini;
      }
    )
  );
}

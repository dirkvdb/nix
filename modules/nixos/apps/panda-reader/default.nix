{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.local.apps.panda-reader;
  user = config.local.user.name;
  dataDirectory = "${config.home-manager.users.${user}.xdg.dataHome}/pandareader";
  jsonFormat = pkgs.formats.json { };
  settingsFile = jsonFormat.generate "panda-reader-preferences.json" cfg.settings;
  mergePreferences = pkgs.writeShellApplication {
    name = "panda-reader-preferences";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      preferences="$1"
      directory="$(dirname "$preferences")"
      mkdir -p "$directory"
      temporary="$(mktemp "$directory/.preferences.json.XXXXXX")"
      trap 'rm -f "$temporary"' EXIT

      if [ -e "$preferences" ]; then
        jq --slurpfile defaults ${settingsFile} '
          if type == "object" then . + $defaults[0]
          else error("Panda Reader preferences must be a JSON object") end
        ' "$preferences" > "$temporary"
      else
        cp ${settingsFile} "$temporary"
      fi

      # Replace atomically with a regular writable file, not a store symlink.
      chmod 600 "$temporary"
      mv -f "$temporary" "$preferences"
    '';
  };
in
{
  options.local.apps.panda-reader = {
    enable = lib.mkEnableOption "Panda Reader RSS reader";
    settings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      description = ''
        Preferences merged into Panda Reader's writable preferences.json on each
        Home Manager activation. Other existing preferences are preserved.
        Do not put provider credentials here; these values enter the Nix store.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.panda-reader ];

    assertions = [
      {
        assertion = config.local.apps.sops.enable;
        message = "Panda Reader requires local.apps.sops.enable for its FreshRSS credentials.";
      }
    ];

    sops.secrets = {
      "panda-reader/endpoint" = { };
      "panda-reader/secret" = { };
    };

    systemd.tmpfiles.settings.panda-reader.${dataDirectory}.d = {
      mode = "0700";
      inherit user;
      group = config.users.users.${user}.group;
    };

    # SOPS can create the parent directory as root before tmpfiles repairs its ownership.
    systemd.services."home-manager-${user}" = lib.mkIf (!config.home-manager.startAsUserService) {
      after = [ "systemd-tmpfiles-resetup.service" ];
    };

    sops.templates."panda-reader-providers" = {
      path = "${dataDirectory}/providers.json";
      owner = config.local.user.name;
      mode = "0400";
      content = builtins.toJSON {
        fresh_rss = {
          endpoint = config.sops.placeholder."panda-reader/endpoint";
          username = config.local.user.name;
          secret = config.sops.placeholder."panda-reader/secret";
        };
      };
    };

    local.apps.panda-reader.settings = {
      library_source = lib.mkDefault "fresh_rss";
      theme = lib.mkDefault "charcoal_grove_dark";
      show_app_icon = lib.mkDefault false;
      ui_font_size = lib.mkDefault 15.0;
      reader_font_family = lib.mkDefault "sans";
      reader_font_size = lib.mkDefault 19.0;
      reader_line_height = lib.mkDefault 1.65;
      vim_navigation = lib.mkDefault true;
      check_for_updates = lib.mkDefault false;
    };

    home-manager.users.${config.local.user.name} =
      { config, ... }:
      {
        home.activation.pandaReaderPreferences =
          inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ]
            ''
              run ${lib.getExe mergePreferences} ${lib.escapeShellArg "${config.xdg.dataHome}/pandareader/preferences.json"}
            '';
      };
  };
}

{
  config,
  inputs,
  lib,
  mkHome,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.obsidian;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless or false;
  tokenSecret = "obsidian/${config.local.system.network.hostname}";
  serverSecret = "obsidian/server_url";
  tokenFile = "/run/secrets/${tokenSecret}";
  serverFile = "/run/secrets/${serverSecret}";

  vaultTargets = builtins.attrValues cfg.vaults;
in
{
  options.local.apps.obsidian = {
    enable = lib.mkEnableOption "Obsidian knowledge base";


    vaults = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        notes = "Documents/Notes";
      };
      description = ''
        Obsidian vaults to generate, as an attribute set from a vault name to a
        path relative to the user's home directory. Lockstep Sync is installed
        and enabled in every generated vault.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && !isHeadless) (mkUserHome {
    programs.obsidian = {
      enable = true;
      package = pkgs.obsidian;
      defaultSettings = {
        app = {
          settingsPopoutWindow = false;
          frameStyle = "native";
        };

        appearance = {
          baseFontSize = lib.mkForce 16;
          showRibbon = false;
          showViewHeader = false;
        };

        communityPlugins = [
          pkgs.obsidianPlugins.lockstep-sync
          pkgs.obsidianPlugins.cooklang-obsidian
        ];

        themes = [
          pkgs.obsidianThemes.minimal
        ];
      };

      vaults = lib.mapAttrs (_name: target: {
        inherit target;
      }) cfg.vaults;
    };

    home.activation.obsidianLockstepSettings = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${lib.concatMapStringsSep "\n" (target: let
        pluginDir = "${user.homeDir}/${target}/.obsidian/plugins/lockstep-sync";
        dataFile = "${pluginDir}/data.json";
      in ''
        plugin_dir=${lib.escapeShellArg pluginDir}
        data_file=${lib.escapeShellArg dataFile}
        if [ -L "$plugin_dir" ]; then
          plugin_copy=$(mktemp -d)
          cp -a "$plugin_dir"/. "$plugin_copy"/
          rm "$plugin_dir"
          mv "$plugin_copy" "$plugin_dir"
        fi
        if [ -d "$plugin_dir" ]; then
          token=""
          server_url=""
          if [ -r ${lib.escapeShellArg tokenFile} ]; then
            token=$(cat ${lib.escapeShellArg tokenFile})
          fi
          if [ -r ${lib.escapeShellArg serverFile} ]; then
            server_url=$(cat ${lib.escapeShellArg serverFile})
          fi
          if [ -f "$data_file" ]; then
            settings=$(cat "$data_file")
          else
            settings='{}'
          fi
          ${pkgs.jq}/bin/jq --arg serverUrl "$server_url" --arg token "$token" \
            '. + {serverUrl: $serverUrl, token: $token}' \
            <<<"$settings" > "$data_file.tmp"
          install -m 600 "$data_file.tmp" "$data_file"
          rm -f "$data_file.tmp"
        fi
      '') vaultTargets}
    '';
  });
}

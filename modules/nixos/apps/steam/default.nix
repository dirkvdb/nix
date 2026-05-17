{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.local.apps.steam;
  user = config.local.user.name;

  # Python script that merges declarative shortcuts into Steam's shortcuts.vdf.
  # Existing manually-added shortcuts are preserved; declarative ones are
  # identified by a tag so they can be updated or removed on rebuild.
  mergeShortcuts =
    pkgs.writers.writePython3 "merge-steam-shortcuts"
      {
        libraries = [ pkgs.python3Packages.vdf ];
      }
      ''
        import json
        import os
        import sys
        import zlib

        import vdf  # type: ignore[import-untyped]

        MANAGED_TAG = "nix-managed"

        shortcuts_json = json.loads(sys.argv[1])
        steam_root = os.path.expanduser("~/.local/share/Steam")
        userdata = os.path.join(steam_root, "userdata")

        if not os.path.isdir(userdata):
            print(f"Steam userdata not found at {userdata}, skipping", file=sys.stderr)
            sys.exit(0)

        for uid in os.listdir(userdata):
            vdf_path = os.path.join(userdata, uid, "config", "shortcuts.vdf")
            os.makedirs(os.path.dirname(vdf_path), exist_ok=True)

            # Load existing shortcuts
            existing: dict = {}
            if os.path.isfile(vdf_path):
                with open(vdf_path, "rb") as f:
                    try:
                        existing = vdf.binary_loads(f.read()).get("shortcuts", {})
                    except Exception:
                        existing = {}

            # Remove old nix-managed entries
            cleaned = {
                k: v for k, v in existing.items()
                if MANAGED_TAG not in v.get("tags", {}).values()
            }

            # Find next free index
            idx = max((int(k) for k in cleaned), default=-1) + 1

            # Add declarative shortcuts
            for entry in shortcuts_json:
                exe = entry["exe"]
                name = entry["appname"]
                # Steam uses crc of exe+appname for app id (signed 32-bit)
                crc = zlib.crc32((exe + name).encode()) & 0xFFFFFFFF
                appid = crc - (1 << 32) if crc >= (1 << 31) else crc
                shortcut = {
                    "appid": appid,
                    "AppName": name,
                    "Exe": exe,
                    "StartDir": entry.get("startdir", os.path.dirname(exe)),
                    "icon": entry.get("icon", ""),
                    "ShortcutPath": "",
                    "LaunchOptions": entry.get("launchoptions", ""),
                    "IsHidden": 0,
                    "AllowDesktopConfig": 1,
                    "AllowOverlay": 1,
                    "OpenVR": 0,
                    "Devkit": 0,
                    "DevkitGameID": "",
                    "DevkitOverrideAppID": 0,
                    "LastPlayTime": 0,
                    "FlatpakAppID": "",
                    "tags": {"0": MANAGED_TAG},
                }
                cleaned[str(idx)] = shortcut
                idx += 1

            data = vdf.binary_dumps({"shortcuts": cleaned})
            with open(vdf_path, "wb") as f:
                f.write(data)
            print(f"Wrote {len(shortcuts_json)} shortcut(s) to {vdf_path}")
      '';

  shortcutsJson = builtins.toJSON (
    map (game: {
      appname = game.name;
      exe = game.exe;
      startdir = game.startDir;
      icon = game.icon;
      launchoptions = game.launchOptions;
    }) cfg.nonSteamGames
  );

in
{
  options.local.apps.steam = {
    enable = lib.mkEnableOption "steam";

    nonSteamGames = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Display name in Steam";
              example = "Fladder";
            };
            exe = lib.mkOption {
              type = lib.types.str;
              description = "Path to the executable";
            };
            startDir = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Working directory";
            };
            icon = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Path to icon file";
            };
            launchOptions = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Extra launch options";
            };
          };
        }
      );
      default = [ ];
      description = "Non-Steam games to add to Steam's library declaratively.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    # Merge declarative shortcuts into every Steam user's shortcuts.vdf
    home-manager.users.${user}.home.activation.steamNonSteamGames =
      lib.mkIf (cfg.nonSteamGames != [ ])
        (
          inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            ${mergeShortcuts} ${lib.escapeShellArg shortcutsJson}
          ''
        );
  };
}

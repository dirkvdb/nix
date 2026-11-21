{
  config,
  lib,
  mkHome,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.services.nixcfg-update;
  hmCfg = config.home-manager.users.${user.name};
  publishAarch64Apps = pkgs.writeShellApplication {
    name = "nixcfg-publish-aarch64-apps";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.nix
      pkgs.xilo-cli
    ];
    text = builtins.readFile ../../../../scripts/publish-aarch64-apps.sh;
  };
  systemOutLink = "%t/nixcfg-update/system";
  publishSystem = pkgs.writeShellScript "nixcfg-publish-built-system" ''
    set -euo pipefail
    system="$1"
    token_file=${
      lib.escapeShellArg (config.sops.secrets.xilo_push_token.path or "/run/secrets/xilo_push_token")
    }
    if [ ! -r "$token_file" ] || [ ! -s "$token_file" ]; then
      echo "System cache token is missing or unreadable: deploy xilo_push_token first." >&2
      exit 1
    fi

    # Use the helper from the build, which knows that build's native kernel outputs.
    export XILO_TOKEN="$(cat "$token_file")"
    exec "$system/sw/bin/nixcfg-push-system" "$system"
  '';
  serviceEnvironment = [
    "NIXCFG_UPDATE_OUT_LINK=${systemOutLink}"
    "PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.git

        pkgs.xilo-cli
        pkgs.nix
        pkgs.nh
        pkgs.openssh
      ]
    }:%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
  ];
in
{
  options.local.services.nixcfg-update.enable =
    lib.mkEnableOption "daily Nix configuration updates with builds";

  config = lib.mkIf cfg.enable (
    mkHome user.name {
      home.packages = [ publishAarch64Apps ];

      systemd.user.services.nixcfg-update = {
        Unit.Description = "Update, build, and push the Nix configuration without switching";
        Service = {
          Type = "oneshot";
          RuntimeDirectory = "nixcfg-update";
          WorkingDirectory = "%h/nix";
          ExecStart = [
            "${hmCfg.home.path}/bin/nixcfg-update --build --commit"
            "${publishAarch64Apps}/bin/nixcfg-publish-aarch64-apps"
            "${publishSystem} ${systemOutLink}"
            "${pkgs.git}/bin/git push"
          ];
          Environment = serviceEnvironment;
        };
      };

      systemd.user.timers.nixcfg-update = {
        Unit.Description = "Update, build, and push the Nix configuration every morning";
        Timer = {
          OnCalendar = "*-*-* 06:00:00";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    }
  );
}

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
  serviceEnvironment = [
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
    lib.mkEnableOption "daily build-only Nix configuration updates";

  config = lib.mkIf cfg.enable (
    mkHome user.name {
      home.packages = [ publishAarch64Apps ];

      systemd.user.services.nixcfg-update = {
        Unit = {
          Description = "Update and build the Nix configuration without switching";
          OnSuccess = [ "aarch64-apps-update.service" ];
        };
        Service = {
          Type = "oneshot";
          WorkingDirectory = "%h/nix";
          ExecStart = "${hmCfg.home.path}/bin/nixcfg-update --build";
          Environment = serviceEnvironment;
        };
      };

      systemd.user.services.aarch64-apps-update = {
        Unit.Description = "Build and publish cross-compiled aarch64 apps";
        Service = {
          Type = "oneshot";
          WorkingDirectory = "%h/nix";
          ExecStart = "${publishAarch64Apps}/bin/nixcfg-publish-aarch64-apps";
          Environment = serviceEnvironment;
        };
      };

      systemd.user.timers.nixcfg-update = {
        Unit.Description = "Update and build the Nix configuration every morning";
        Timer = {
          OnCalendar = "*-*-* 06:00:00";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    }
  );
}

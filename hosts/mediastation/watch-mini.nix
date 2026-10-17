{ config, pkgs, ... }:
let
  inherit (config.local) user;
  stateDirectory = "/var/lib/watch-mini";
in
{
  programs.ssh.knownHosts."mini.fritz.box" = {
    extraHostNames = [ "mini" ];
    # Verified on mini itself, not collected from an unauthenticated network scan.
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChJpt2O/Vl9QeHHLojMLVKxdyhsdZ7/s18RpRmZRdf/";
  };

  systemd.tmpfiles.rules = [
    "d ${stateDirectory} 0700 ${user.name} ${user.name} 7d"
  ];

  systemd.services.watch-mini = {
    description = "Record mini's LAN responsiveness and pressure statistics";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    startLimitIntervalSec = 0;
    path = [
      pkgs.openssh
      pkgs.iputils
    ];
    environment.HOME = user.homeDir;
    serviceConfig = {
      Type = "simple";
      User = user.name;
      Group = user.name;
      StateDirectory = "watch-mini";
      StateDirectoryMode = "0700";
      WorkingDirectory = stateDirectory;
      UMask = "0077";
      ExecStart = "${pkgs.python3}/bin/python3 ${../../scripts/watch-mini.py} ${user.name}@mini.fritz.box ${stateDirectory} --hours 24";
      # Rotate bounded sessions, and retry failed SSH preflights even after boot.
      Restart = "always";
      RestartSec = "1min";
      TimeoutStopSec = "10s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
    };
  };
}

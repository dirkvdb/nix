{
  config,
  pkgs,
  lib,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  sopsEnabled = config.local.apps.sops.enable or false;
  winboatEnabled = config.local.apps.winboat.enable or false;
  proxyPacUrl = config.local.system.network.proxy.pacUrl;
  proxyEnabled = proxyPacUrl != null;
  mkUserHome = mkHome user.name;
in
{
  config = mkUserHome {
    home.packages =
      (with pkgs; [
        websocat
      ])
      ++ lib.optionals proxyEnabled [ pkgs.connect ];
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings = {
        mini = {
          HostName = "mini.local";
          User = "dirk";
          RequestTTY = "yes";
          ForwardAgent = true;
        };
        mini-remote = lib.mkIf sopsEnabled {
          User = "dirk";
          ProxyCommand = "websocat -b $(cat ${config.sops.secrets.ssh_websocat_host.path})";
          ControlMaster = "no";
          ControlPath = "none";
          ControlPersist = "no";
        };
        winboat = lib.mkIf winboatEnabled {
          HostName = "127.0.0.1";
          User = "dirk";
          Port = 2222;
          RequestTTY = "yes";
          ForwardAgent = true;
        };
        inky = {
          HostName = "inky.local";
          User = "dirk";
          ForwardAgent = true;
        };
        odroid = {
          HostName = "odroid.local";
          User = "dirk";
        };
        macmini = {
          HostName = "macmini.local";
          User = "dirk";
          ForwardAgent = true;
        };
        nas = {
          HostName = "nas.local";
          User = "dirk";
          Port = 6987;
          RequestTTY = "yes";
          SetEnv = {
            TERM = "vt100";
          };
        };
        cluster = {
          HostName = "develop.marvin.vito.local";
          User = "vdboerd";
          ProxyCommand = lib.mkIf proxyEnabled "${pkgs.connect}/bin/connect -S 127.0.0.1:1080 %h %p";
          ForwardAgent = true;
          #   RemoteCommand = "fish";
          #   RequestTTY = "yes";
        };
        clusterfs = {
          HostName = "develop.marvin.vito.local";
          ProxyCommand = lib.mkIf proxyEnabled "${pkgs.connect}/bin/connect -S 127.0.0.1:1080 %h %p";
          User = "vdboerd";
          ForwardAgent = true;
        };
      };
    };
  };
}

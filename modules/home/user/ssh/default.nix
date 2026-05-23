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

      matchBlocks = {
        mini = {
          hostname = "mini.local";
          user = "dirk";
          extraOptions = {
            requestTTY = "true";
            ForwardAgent = "yes";
          };
        };
        mini-remote = lib.mkIf sopsEnabled {
          user = "dirk";
          extraOptions = {
            ProxyCommand = "websocat -b $(cat ${config.sops.secrets.ssh_websocat_host.path})";
            ControlMaster = "no";
            ControlPath = "none";
            ControlPersist = "no";
          };
        };
        inky = {
          hostname = "inky.local";
          user = "dirk";
          extraOptions = {
            ForwardAgent = "yes";
          };
        };
        odroid = {
          hostname = "odroid.local";
          user = "dirk";
        };
        macmini = {
          hostname = "macmini.local";
          user = "dirk";
          extraOptions = {
            ForwardAgent = "yes";
          };
        };
        nas = {
          hostname = "nas.local";
          user = "dirk";
          port = 6987;
          extraOptions = {
            requestTTY = "true";
            SetEnv = "TERM=vt100";
          };
        };
        cluster = {
          hostname = "develop.marvin.vito.local";
          user = "vdboerd";
          proxyCommand = lib.mkIf proxyEnabled "${pkgs.connect}/bin/connect -S 127.0.0.1:1080 %h %p";
          extraOptions = {
            ForwardAgent = "yes";
            #   remoteCommand = "fish";
            #   requestTTY = "true";
          };
        };
        clusterfs = {
          hostname = "develop.marvin.vito.local";
          proxyCommand = lib.mkIf proxyEnabled "${pkgs.connect}/bin/connect -S 127.0.0.1:1080 %h %p";
          user = "vdboerd";
          extraOptions = {
            ForwardAgent = "yes";
          };
        };
      };
    };
  };
}

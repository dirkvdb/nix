{
  config,
  lib,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  winboatEnabled = config.local.apps.winboat.enable or false;
  proxyPacUrl = config.local.system.network.proxy.pacUrl;
  proxyEnabled = proxyPacUrl != null;
  socksProxyUrl = config.local.services.vpnjumphost.socksProxyUrl;
  vpnjumphostEnabled = config.local.services.vpnjumphost.enable;
  mkUserHome = mkHome user.name;
in
{
  config = mkUserHome {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks = {
        mini = {
          hostname = "mini.fritz.box";
          user = "dirk";
          forwardAgent = true;
          extraOptions.RequestTTY = "yes";
        };
        mediastation = {
          hostname = "mediastation.fritz.box";
          user = "dirk";
          forwardAgent = true;
          extraOptions.RequestTTY = "yes";
        };
        work = {
          hostname = "p260182.fritz.box";
          user = "dirk";
          forwardAgent = true;
          extraOptions.RequestTTY = "yes";
        };
        winboat = lib.mkIf winboatEnabled {
          hostname = "127.0.0.1";
          user = "dirk";
          port = 2222;
          forwardAgent = true;
          sendEnv = [ "ARTIFACTORY_TOKEN" ];
          extraOptions = lib.optionalAttrs vpnjumphostEnabled {
            ExitOnForwardFailure = "yes";
            RemoteForward = "1080 ${socksProxyUrl}";
          };
        };
        inky = {
          hostname = "inky.fritz.box";
          user = "dirk";
          forwardAgent = true;
        };
        odroid = {
          hostname = "odroid.fritz.box";
          user = "dirk";
        };
        macmini = {
          hostname = "macmini.fritz.box";
          user = "dirk";
          forwardAgent = true;
        };
        nas = {
          hostname = "nas.fritz.box";
          user = "dirk";
          port = 6987;
          setEnv = {
            TERM = "vt100";
          };
          extraOptions = {
            RequestTTY = "yes";
            WarnWeakCrypto = "no-pq-kex";
          };
        };
        cluster = {
          hostname = "develop.marvin.vito.local";
          user = "vdboerd";
          proxyCommand = lib.mkIf proxyEnabled "nc -x ${socksProxyUrl} -X 5 %h %p";
          forwardAgent = true;
          #   RemoteCommand = "fish";
          #   RequestTTY = "yes";
        };
        clusterfs = {
          hostname = "develop.marvin.vito.local";
          proxyCommand = lib.mkIf proxyEnabled "nc -x ${socksProxyUrl} -X 5 %h %p";
          user = "vdboerd";
          forwardAgent = true;
        };
        "*.vito.be *.vito.local" = lib.mkIf vpnjumphostEnabled {
          proxyCommand = "nc -x 127.0.0.1:1080 -X 5 %h %p";
        };
      };
    };
  };
}

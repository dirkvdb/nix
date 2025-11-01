{ config, ... }:
let
  inherit (config.local) user;
in
{
  home-manager.users.${user.name} = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          extraOptions = {
            AddKeysToAgent = "yes";
            Compression = "yes";
            ControlMaster = "auto";
            ControlPath = "~/.ssh/master-%r@%n:%p";
            ControlPersist = "10m";
            ServerAliveInterval = "60";
          };
        };
        mini = {
          hostname = "mini.local";
          user = "dirk";
          extraOptions = {
            requestTTY = "true";
          };
        };
        inky = {
          hostname = "inky.local";
          user = "dirk";
        };
        vito = {
          hostname = "192.168.1.43";
          user = "Vito\\vdboerd";
        };
        odroid = {
          hostname = "odroid.local";
          user = "dirk";
        };
        nas = {
          hostname = "nas.local";
          user = "dirk";
          port = 6987;
        };
        cluster = {
          hostname = "develop.marvin.vito.local";
          user = "vdboerd";
          proxyCommand = "nc -x localhost:1080 -X 5 %h %p";
          # extraOptions = {
          #   remoteCommand = "fish";
          #   requestTTY = "true";
          # };
        };
        clusterfs = {
          hostname = "develop.marvin.vito.local";
          proxyCommand = "nc -x localhost:1080 -X 5 %h %p";
          user = "vdboerd";
        };
      };
    };
  };
}

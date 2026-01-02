{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.services.docker;
  inherit (config.local) user;
in
{
  options.local.services.docker = {
    enable = lib.mkEnableOption "Enable docker service";
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      containers.enable = true;
      libvirtd.enable = true;
      docker = {
        enable = true;
        rootless = {
          enable = false;
          setSocketVariable = true;
        };
      };
    };

    environment.systemPackages = with pkgs; [
      lazydocker
      docker-credential-helpers
    ];

    users.users.${user.name}.extraGroups = [
      "docker"
    ];

    home-manager.users.${user.name} = {
      home.file.".docker/config.json".text = builtins.toJSON {
        credsStore = "secretservice";
      };
    };
  };
}

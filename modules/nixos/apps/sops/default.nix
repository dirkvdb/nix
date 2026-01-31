{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.sops;

in
{
  # sops does not have official darwin support, but works through home-manager
  config = lib.mkIf cfg.enable (
    let
      inherit (config.local) user;
    in
    {
      environment.systemPackages = with pkgs; [
        sops
      ];
      sops = {
        age.keyFile = "/home/${user.name}/.config/sops/age/keys.txt";

        defaultSopsFile = ./secrets.yaml;
        defaultSopsFormat = "yaml";

        secrets.openai_api_key = {
          owner = user.name;
        };

        secrets.github_token = {
          owner = user.name;
        };

        secrets.mqtt_pass = {
          owner = user.name;
        };

        secrets.ssh_websocat_host = {
          owner = user.name;
        };
      };
    }
  );
}

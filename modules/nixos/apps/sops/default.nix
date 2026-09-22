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
        age.keyFile =
          if cfg.ageKeyFile.path != null then
            cfg.ageKeyFile.path
          else
            "/home/${user.name}/.config/sops/age/keys.txt";

        defaultSopsFile = ./secrets.yaml;
        defaultSopsFormat = "yaml";

        secrets.github_token = {
          owner = user.name;
        };

        secrets.spotifast_web_client_id = {
          owner = user.name;
        };

        secrets.copilot_github_token = {
          owner = user.name;
        };

        secrets.jira_personal_token = {
          owner = user.name;
        };

        secrets.affine_mcp_token = {
          owner = user.name;
        };

        secrets.affine_mcp_url = {
          owner = user.name;
        };

        secrets.home_assistant_api_key = {
          owner = user.name;
        };

        secrets.artifactory_token = {
          owner = user.name;
        };

        secrets."obsidian/server_url" = {
          owner = user.name;
        };

        secrets."obsidian/${config.local.system.network.hostname}" = {
          owner = user.name;
        };

        secrets.cachix_geo_overlay_auth_token = {
          owner = user.name;
        };

        secrets.xilo_push_token = {
          owner = user.name;
        };

        secrets.mqtt_pass = {
          owner = user.name;
        };

        secrets.noctalia_storage_key = {
          owner = user.name;
        };

        secrets.vito_outlook_ics_url = {
          owner = user.name;
        };

        secrets.tailscale_client_secret = {
          owner = "root";
          group = "root";
          mode = "0400";
        };

        secrets."vpnjumphost/username" = {
          owner = user.name;
        };

        secrets."vpnjumphost/password" = {
          owner = user.name;
        };
      };
    }
  );
}

{
  config,
  lib,
  pkgs,
  ...
}:

let
  user = config.local.user.name;
  vpnjumphostEnabled = config.local.services.vpnjumphost.enable;
  jiraEnabled = config.local.apps.mcp.jira.enable && vpnjumphostEnabled;
in
{
  options.local.apps.mcp.jira.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable the Jira Atlassian MCP server.";
  };

  options.local.apps.mcp.solidcraft.enable =
    lib.mkEnableOption "Solidcraft MCP integration for AI clients";

  config.home-manager.users.${user} = {
    programs.mcp = {
      enable = true;
      servers.solidcraft = lib.mkIf config.local.apps.mcp.solidcraft.enable {
        command = "${pkgs.solidcraft}/bin/solidcraft-cli";
        args = [ "mcp" ];
      };
      servers.jira = lib.mkIf jiraEnabled {
        command = "uvx";
        args = [ "mcp-atlassian" ];
        env = {
          JIRA_URL.file = config.sops.secrets.jira_url.path;
          JIRA_USERNAME.file = config.sops.secrets.vito_username.path;
          JIRA_API_TOKEN.file = config.sops.secrets.jira_api_token.path;
        };
      };

    };

    programs.zed-editor.enableMcpIntegration = true;
  };
}

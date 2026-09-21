{ config, lib, ... }:

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

  config.home-manager.users.${user} = {
    programs.mcp = {
      enable = true;
      servers.jira = lib.mkIf jiraEnabled {
        command = "uvx";
        args = [ "mcp-atlassian" ];
        env = {
          HTTPS_PROXY = "socks5://127.0.0.1:1080";
          JIRA_URL = "https://jira.vito.be";
          JIRA_PERSONAL_TOKEN.file = config.sops.secrets.jira_personal_token.path;
        };
      };
      servers.affine = {
        command = "sh";
        args = [
          "-c"
          ''exec uvx --with "mcp<2" mcp-proxy --transport=streamablehttp --stateless "$AFFINE_MCP_URL/api/workspaces/5f0a038e-be51-470a-8fef-ec17b58fb0fd/mcp"''
        ];
        env = {
          AFFINE_MCP_URL.file = config.sops.secrets.affine_mcp_url.path;
          API_ACCESS_TOKEN.file = config.sops.secrets.affine_mcp_token.path;
        };
      };
    };

    programs.zed-editor.enableMcpIntegration = true;
  };
}

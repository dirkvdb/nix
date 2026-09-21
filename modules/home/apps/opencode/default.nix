{
  lib,
  config,
  pkgs,
  options,
  mkHome,
  llmAgentsPkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.opencode;
  sopsEnabled = config.local.apps.sops.enable or false;
  sopsAvailable = options ? sops.templates;
  vpnjumphostEnabled = config.local.services.vpnjumphost.enable;
  mkUserHome = mkHome user.name;
  opencodeBaseSettings = {
    "$schema" = "https://opencode.ai/config.json";
    enabled_providers = [
      "openai"
      "github-copilot"
      "lemonade"
    ];
    provider.lemonade = {
      npm = "@ai-sdk/openai-compatible";
      name = "Lemonade (local)";
      options.baseURL = "http://mini.fritz.box:13305/api/v0";
    };
    permission = {
      "*" = "allow";
      bash = {
        "*" = "allow";
        sudo = "deny";
        "sudo *" = "deny";
      };
    };
  };
  opencodeMcpSettings = {
    affine = {
      type = "local";
      command = [
        "sh"
        "-c"
        ''exec uvx --with "mcp<2" mcp-proxy --transport=streamablehttp --stateless "$AFFINE_MCP_URL/api/workspaces/5f0a038e-be51-470a-8fef-ec17b58fb0fd/mcp"''
      ];
      environment = {
        AFFINE_MCP_URL = config.sops.placeholder.affine_mcp_url;
        API_ACCESS_TOKEN = config.sops.placeholder.affine_mcp_token;
      };
      enabled = true;
    };
  }
  // lib.optionalAttrs vpnjumphostEnabled {
    jira = {
      type = "local";
      command = [ "uvx" "mcp-atlassian" ];
      environment = {
        HTTPS_PROXY = "socks5://127.0.0.1:1080";
        JIRA_URL = "https://jira.vito.be";
        JIRA_PERSONAL_TOKEN = config.sops.placeholder.jira_personal_token;
      };
      enabled = true;
    };
  }
  // lib.optionalAttrs cfg.homeAssistantMcp.enable {
    "home-assistant" = {
      type = "local";
      command = [
        "uvx"
        "--with"
        "mcp<2"
        "mcp-proxy"
        "--transport=streamablehttp"
        "--stateless"
        "https://ha.egstraat.synology.me/api/mcp"
      ];
      environment.API_ACCESS_TOKEN = config.sops.placeholder.home_assistant_api_key;
      enabled = true;
    };
  };
  opencodeSettings = opencodeBaseSettings // {
    mcp = opencodeMcpSettings;
  };
in
{
  options.local.apps.opencode = {
    enable = lib.mkEnableOption "OpenCode AI coding agent";
    homeAssistantMcp.enable = lib.mkEnableOption "Home Assistant MCP server";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.optionalAttrs sopsAvailable {
      assertions = [
        {
          assertion = sopsEnabled;
          message = "local.apps.opencode.enable requires local.apps.sops.enable for the OpenCode configuration template.";
        }
      ];

      # Keep the generated OpenCode configuration out of the world-readable Nix store.
      sops.templates."opencode-config" = {
        path = "/home/${user.name}/.config/opencode/opencode.json";
        owner = user.name;
        mode = "0400";
        content = builtins.toJSON opencodeSettings;
      };
    })
    (mkUserHome {
      programs.opencode = {
        enable = true;
        package = llmAgentsPkgs.opencode;
        settings = lib.optionalAttrs (!sopsAvailable) opencodeBaseSettings;
      };

      # OpenCode custom providers do not discover /models themselves. Populate
      # the provider from Lemonade at startup so its model list stays dynamic.
      xdg.configFile."opencode/plugins/lemonade-models.js".text = ''
          export const LemonadeModels = async () => ({
            config: async (config) => {
              const provider = config.provider?.lemonade
              const baseURL = provider?.options?.baseURL
              if (!baseURL) return

              try {
                const response = await fetch(baseURL.replace(/\/$/, "") + "/models")
                if (!response.ok) return

                const payload = await response.json()
                const models = Array.isArray(payload.data) ? payload.data : []
                provider.models = Object.fromEntries(
                  models
                    .filter((model) => typeof model.id === "string")
                    .map((model) => {
                      const labels = new Set(Array.isArray(model.labels) ? model.labels : [])
                      return [
                        model.id,
                        {
                          name: model.id,
                          attachment: labels.has("vision"),
                          reasoning: labels.has("reasoning"),
                          tool_call: labels.has("tool-calling"),
                        },
                      ]
                    }),
                )
              } catch {
                // Lemonade may be unavailable while OpenCode starts.
              }
            },
          })
        '';

      home.packages = [
        pkgs.uv
      ] ++ lib.optional (
        !config.local.headless && pkgs.stdenv.isLinux
      ) llmAgentsPkgs.opencode-desktop;
    })
  ]);
}

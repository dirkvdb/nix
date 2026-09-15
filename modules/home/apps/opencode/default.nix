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
  opencodeSettings = opencodeBaseSettings // lib.optionalAttrs cfg.homeAssistantMcp.enable {
    mcp."home-assistant" = {
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

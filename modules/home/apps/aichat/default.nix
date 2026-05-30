{
  lib,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.aichat;
  lemonade = config.local.apps.lemonade;
  sopsEnabled = config.local.apps.sops.enable or false;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.aichat = {
    enable = lib.mkEnableOption "aichat AI chat tool";

    lemonade.models = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [
        {
          name = "gemma4-it-e4b-FLM";
          supports_vision = true;
          supports_function_calling = true;
        }
        {
          name = "qwen3.5-9b-FLM";
          supports_vision = true;
          supports_function_calling = true;
        }
      ];
      description = "Models to expose from the local lemonade server.";
    };
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    programs.aichat = {
      enable = true;
      settings = {
        model = "github:gpt-5";
        clients =
          lib.optional lemonade.enable {
            type = "openai-compatible";
            name = "lemonade";
            api_base = "http://localhost:${toString lemonade.port}/api/v0";
            models = cfg.lemonade.models;
          }
          ++ lib.optional sopsEnabled {
            type = "openai-compatible";
            name = "github";
            api_base = "https://models.inference.ai.azure.com";
            # api_key is not stored in the Nix store; aichat reads GITHUB_API_KEY at runtime
          };
      };
    };

    home.shellAliases.ai = "aichat";

    # Expose the GitHub token under the name aichat expects for the "github" client.
    # Uses the same sops-managed file that GITHUB_TOKEN already reads from.
    programs.fish.shellInit = lib.optionalString sopsEnabled ''
      set -gx GITHUB_API_KEY (cat ${config.sops.secrets.github_token.path} | string trim)
    '';
  });
}

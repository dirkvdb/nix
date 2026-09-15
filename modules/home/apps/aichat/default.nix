{
  lib,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.aichat;
  npuCfg = config.hardware.amd-npu or { };
  lemonadePort = (npuCfg.lemonade or { }).port or 13305;
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
        {
          name = "Qwen3.5-4B-MTP-GGUF";
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
        model = "lemonade:Qwen3.5-4B-MTP-GGUF";
        clients = [
          {
            type = "openai-compatible";
            name = "lemonade";
            api_base = "http://mini.fritz.box:${toString lemonadePort}/api/v0";
            models = cfg.lemonade.models;
          }
        ];
      };
    };

    home.shellAliases.ai = "aichat";

  });
}

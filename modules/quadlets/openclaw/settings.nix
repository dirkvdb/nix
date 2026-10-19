{
  gateway = {
    mode = "local";
    auth.mode = "token";
    controlUi.allowedOrigins = [
      "http://127.0.0.1:18789"
      "http://localhost:18789"
    ];
  };

  models = {
    mode = "replace";
    providers.lemonade = {
      baseUrl = "https://ai.hl.vandenboer.eu/v1";
      api = "openai-completions";
      # This OpenClaw release requires a key even for an unauthenticated provider.
      apiKey = "lemonade-local";
      authHeader = false;
      models = [
        {
          id = "qwen3.6-moe-35b-a3b-FLM";
          name = "Qwen 3.6 MoE 35B A3B (FLM)";
          reasoning = true;
          input = [
            "text"
            "image"
          ];
          contextWindow = 65536;
          maxTokens = 8192;
          compat = {
            supportsTools = true;
            supportsReasoningEffort = false;
          };
          cost = {
            input = 0;
            output = 0;
            cacheRead = 0;
            cacheWrite = 0;
          };
        }
      ];
    };
  };

  agents.defaults = {
    workspace = "/home/node/.openclaw/workspace";
    model.primary = "lemonade/qwen3.6-moe-35b-a3b-FLM";
    subagents.model = "lemonade/qwen3.6-moe-35b-a3b-FLM";
  };

  # No embedding model is configured on the inference server.
  memory.search.enabled = false;
}

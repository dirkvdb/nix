{
  lib,
  config,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.apps.lemonade;
in
{
  options.local.apps.lemonade = {
    enable = lib.mkEnableOption "lemonade LLM server";

    package = lib.mkOption {
      type = lib.types.package;
      default =
        if cfg.llamacppBackend == "rocm" then
          pkgs.lemonade-server.override {
            llama-cpp-rocm = unstablePkgs.llama-cpp-rocm;
            stable-diffusion-cpp-rocm = unstablePkgs.stable-diffusion-cpp-rocm;
          }
        else
          pkgs.lemonade-server;
      defaultText = lib.literalExpression "pkgs.lemonade-server";
      description = "The lemonade-server package to use.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address to bind to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Port to listen on.";
    };

    modelPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to the model file. If null, must be specified via extraArgs.";
    };

    llamacppBackend = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "cpu"
          "cuda"
          "rocm"
          "metal"
        ]
      );
      default = null;
      example = "rocm";
      description = "Backend to use for llama.cpp inference.";
    };

    contextSize = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 16000;
      description = "Context size for the model.";
    };

    extraModelsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/models/";
      description = "Additional directory to search for models.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--threads 8"
        "--gpu-layers 35"
      ];
      description = "Additional command-line arguments to pass to lemonade.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "lemonade";
      description = "User account under which lemonade runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "lemonade";
      description = "Group under which lemonade runs.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for the lemonade server port.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      pkgs.lemonade-app
    ];

    users.users.${cfg.user} = lib.mkIf (cfg.user == "lemonade") {
      isSystemUser = true;
      group = cfg.group;
      description = "Lemonade LLM server user";
    };

    users.groups.${cfg.group} = lib.mkIf (cfg.group == "lemonade") { };

    systemd.services.lemonade = {
      description = "Lemonade LLM Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        LEMONADE_CACHE_DIR = "/var/cache/lemonade";
        HF_HOME = "/var/cache/lemonade/huggingface";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = lib.escapeShellArgs (
          [
            "${cfg.package}/bin/lemonade-server"
            "--host"
            cfg.host
            "--port"
            (toString cfg.port)
          ]
          ++ lib.optionals (cfg.modelPath != null) [
            "--model"
            (toString cfg.modelPath)
          ]
          ++ lib.optionals (cfg.llamacppBackend != null) [
            "--llamacpp"
            cfg.llamacppBackend
          ]
          ++ lib.optionals (cfg.contextSize != null) [
            "--ctx-size"
            (toString cfg.contextSize)
          ]
          ++ lib.optionals (cfg.extraModelsDir != null) [
            "--extra-models-dir"
            (toString cfg.extraModelsDir)
          ]
          ++ cfg.extraArgs
        );
        Restart = "on-failure";
        RestartSec = "5s";

        # Log file configuration for app streaming
        # Logs written to journal and also tee'd to /tmp/lemonade-server.log via wrapper
        StandardOutput = "journal";
        StandardError = "journal";

        # Security hardening
        # ProtectSystem = "full" allows /tmp access while protecting /usr, /boot, /efi
        NoNewPrivileges = true;
        ProtectSystem = "full";
        ProtectHome = true;

        # Runtime directory for state
        RuntimeDirectory = "lemonade";
        # Cache directory for downloaded binaries
        CacheDirectory = "lemonade";
        # State directory for persistent data
        StateDirectory = "lemonade";

        # Capabilities
        AmbientCapabilities = "";
        CapabilityBoundingSet = "";

        # System call filtering - relaxed for ROCm/HIP operations
        # ROCm requires access to GPU resources and thread creation
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}

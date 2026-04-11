{
  lib,
  config,
  pkgs,
  unstablePkgs,
  mkHome,
  inputs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.lemonade;
  mkUserHome = mkHome user.name;

  lemonadeConfig = {
    host = cfg.host;
    port = cfg.port;
  }
  // lib.optionalAttrs (cfg.contextSize != null) { ctx_size = cfg.contextSize; }
  // lib.optionalAttrs (cfg.extraModelsDir != null) {
    extra_models_dir = toString cfg.extraModelsDir;
  }
  // lib.optionalAttrs (cfg.llamacppBackend != null) {
    llamacpp = {
      backend = cfg.llamacppBackend;
    }
    // lib.optionalAttrs (cfg.llamacppBackend == "rocm") {
      rocm_bin = "${unstablePkgs.llama-cpp-rocm}/bin/llama-server";
    };
  }
  // lib.optionalAttrs (cfg.llamacppBackend == "rocm") {
    sdcpp.rocm_bin = "${unstablePkgs.stable-diffusion-cpp-rocm}/bin/sd-server";
  };

  configFile = pkgs.writeText "lemonade-config.json" (builtins.toJSON lemonadeConfig);
in
{
  options.local.apps.lemonade = {
    enable = lib.mkEnableOption "lemonade LLM server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.lemonade-server;
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
      default = 13305;
      description = "Port to listen on.";
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
      description = "Default context size for LLM models.";
    };

    extraModelsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/models/";
      description = "Additional directory to scan for GGUF model files.";
    };
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    home.packages = [
      cfg.package
      pkgs.lemonade-app
    ];

    # Write config.json during home-manager activation. Using cp (not a symlink)
    # so that lemond can update it at runtime via `lemonade config set`. The file
    # is reset to the Nix-declared values on the next `nixos-rebuild switch`.
    home.activation.lemonadeConfig = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.cache/lemonade"
      $DRY_RUN_CMD cp --no-preserve=mode ${configFile} "$HOME/.cache/lemonade/config.json"
    '';

    systemd.user.services.lemonade = {
      Unit = {
        Description = "Lemonade LLM Server";
        After = [ "network.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/lemond";
        Restart = "on-failure";
        RestartSec = "5s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  });
}

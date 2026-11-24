{
  lib,
  config,
  pkgs,
  mkHome,
  unstablePkgs,
  llmAgentsPkgs,
  ...
}:
let
  cfg = config.local.system.dev;
  inherit (config.local) user;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless or false;
  vpnjumphostEnabled = config.local.services.vpnjumphost.enable or false;

in
{
  options.local.system.dev = {
    enable = lib.mkEnableOption "Developer-focused tooling (devenv, just, lazygit, etc.)";

    llmClis.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the LLM coding agent CLIs (codex, copilot-cli).";
    };
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    home.packages =
      with pkgs;
      [
        serie
        binsider
        nixd
        oweka
        unstablePkgs.sccache
        unstablePkgs.pixi
      ]
      ++ lib.optionals (!isHeadless) [
        tabulite
        ai-usagebar
      ]
      ++ lib.optionals (pkgs.stdenv.isLinux && cfg.llmClis.enable) [
        llmAgentsPkgs.codex
        llmAgentsPkgs.copilot-cli
      ];

    programs.devenv = {
      enable = true;
      package = unstablePkgs.devenv;
    };

    xdg.configFile."devenv/config.yaml".text = ''
      version: 1
      tui:
        statusline:
          enabled: false
    '';

    programs.lazygit = {
      enable = true;
    };

    # Use sccache to cache Rust builds
    home.file.".cargo/config.toml".text = ''
      [build]
      rustc-wrapper = "${unstablePkgs.sccache}/bin/sccache"
    '';

    # Pixi configuration
    xdg.configFile."pixi/config.toml".text = ''
      [shell]
      change-ps1 = false
    ''
    + lib.optionalString vpnjumphostEnabled ''

      [proxy-config]
      http = "socks5h://127.0.0.1:1081"
      https = "socks5h://127.0.0.1:1081"
    '';

    xdg.configFile."ai-usagebar/config.toml" = lib.mkIf (!isHeadless) {
      text = ''
        [ui]
        primary = "copilot"

        [anthropic]
        enabled = false

        [openai]
        enabled = true

        [copilot]
        enabled = true

        [zai]
        enabled = false

        [openrouter]
        enabled = false

        [commandcode]
        enabled = false
      '';
    };
  });
}

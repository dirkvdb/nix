{
  lib,
  config,
  pkgs,
  mkHome,
  llmAgentsPkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.chatgpt;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.chatgpt = {
    enable = lib.mkEnableOption "ChatGPT desktop application";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) (mkUserHome {
    home.packages = [ llmAgentsPkgs.chatgpt ];
  });
}

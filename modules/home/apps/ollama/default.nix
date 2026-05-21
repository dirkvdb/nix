{
  lib,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.ollama;
  amd = config.local.system.video.amd.enable;
  nvidia = config.local.system.video.nvidia.enable;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.ollama = {
    enable = lib.mkEnableOption "Ollama AI model tool";
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    services.ollama = {
      enable = true;
      acceleration =
        if amd then
          "rocm"
        else if nvidia then
          "cuda"
        else
          null;
    };
  });
}

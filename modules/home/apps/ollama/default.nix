{
  lib,
  config,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.ollama;
  amd = config.local.system.video.amd.enable or false;
in
{
  options.local.apps.ollama = {
    enable = lib.mkEnableOption "Ollama AI model tool";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user.name} = {
      services.ollama = {
        enable = true;
        acceleration = if amd then "rocm" else null;
      };
    };
  };
}

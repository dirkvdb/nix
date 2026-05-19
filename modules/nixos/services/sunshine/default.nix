{
  lib,
  config,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.services.sunshine;
  retroCfg = config.local.apps.retro-emulation;

  sunshine-create-display = pkgs.writeShellApplication {
    name = "sunshine-create-display";
    runtimeInputs = [ pkgs.hyprland ];
    text = builtins.readFile ./sunshine-create-display.sh;
  };

  sunshine-remove-display = pkgs.writeShellApplication {
    name = "sunshine-remove-display";
    runtimeInputs = [ pkgs.hyprland ];
    text = builtins.readFile ./sunshine-remove-display.sh;
  };

  sunshine-launch-esde = pkgs.writeShellApplication {
    name = "sunshine-launch-esde";
    runtimeInputs = [
      pkgs.es-de
      pkgs.hyprland
    ];
    text = ''
      hyprctl dispatch exec "[workspace name:sunshine silent; monitor SUNSHINE] ${pkgs.es-de}/bin/es-de"
    '';
  };

  sunshine-launch-zelda-botw = pkgs.writeShellApplication {
    name = "sunshine-launch-zelda-botw";
    runtimeInputs = [
      unstablePkgs.eden
      pkgs.hyprland
    ];
    text = ''
      hyprctl dispatch exec "[workspace name:sunshine silent; monitor SUNSHINE] ${unstablePkgs.eden}/bin/eden -f -i Moonlight '/nas/arr/ROMs/switch/The Legend of Zelda Breath of the Wild.nsp'"
    '';
  };

  sunshine-launch-bluey = pkgs.writeShellApplication {
    name = "sunshine-launch-bluey";
    runtimeInputs = [
      unstablePkgs.eden
      pkgs.hyprland
    ];
    text = ''
      hyprctl dispatch exec "[workspace name:sunshine silent; monitor SUNSHINE] ${unstablePkgs.eden}/bin/eden -f -i Moonlight '/nas/arr/ROMs/switch/Bluey the Videogame [01008C2019598000][v0].nsp'"
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      sunshine-create-display
      sunshine-remove-display
    ];

    services.sunshine = {
      enable = true;
      autoStart = true;

      openFirewall = true;

      settings = {
        fps = 60;
        min_fps_factor = 1;
        channels = 2;
        encoder = "vaapi";
        output_name = 2;
        origin_web_ui_allowed = "lan";
      };

      applications.apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
          prep-cmd = [
            {
              do = "${sunshine-create-display}/bin/sunshine-create-display";
              undo = "${sunshine-remove-display}/bin/sunshine-remove-display";
            }
          ];
        }
      ]
      ++ lib.optionals retroCfg.enable [
        {
          name = "ES-DE";
          detached = [ "${sunshine-launch-esde}/bin/sunshine-launch-esde" ];
          image-path = "${../../apps/retro-emulation/esde.png}";
          prep-cmd = [
            {
              do = "${sunshine-create-display}/bin/sunshine-create-display";
              undo = "${sunshine-remove-display}/bin/sunshine-remove-display";
            }
          ];
          auto-detach = "true";
        }
        {
          name = "Zelda Breath of the Wild";
          image-path = "${./zelda-botw.png}";
          detached = [ "${sunshine-launch-zelda-botw}/bin/sunshine-launch-zelda-botw" ];
          prep-cmd = [
            {
              do = "${sunshine-create-display}/bin/sunshine-create-display";
              undo = "${sunshine-remove-display}/bin/sunshine-remove-display";
            }
          ];
          auto-detach = "true";
        }
        {
          name = "Bluey";
          image-path = "${./bluey.png}";
          detached = [ "${sunshine-launch-bluey}/bin/sunshine-launch-bluey" ];
          prep-cmd = [
            {
              do = "${sunshine-create-display}/bin/sunshine-create-display";
              undo = "${sunshine-remove-display}/bin/sunshine-remove-display";
            }
          ];
          auto-detach = "true";
        }
      ];
    };
  };
}

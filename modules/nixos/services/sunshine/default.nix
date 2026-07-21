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
      hyprctl dispatch exec "[workspace name:sunshine silent; monitor SUNSHINE] ${unstablePkgs.eden}/bin/eden -f -input-profile Moonlight '/nas/arr/ROMs/switch/The Legend of Zelda Breath of the Wild.nsp'"
    '';
  };

  sunshine-kill-eden = pkgs.writeShellApplication {
    name = "sunshine-kill-eden";
    runtimeInputs = [ pkgs.procps ];
    text = ''
      pkill -9 -f '${unstablePkgs.eden}/bin/eden' || true
    '';
  };

  sunshine-launch-bluey = pkgs.writeShellApplication {
    name = "sunshine-launch-bluey";
    runtimeInputs = [
      unstablePkgs.eden
      pkgs.hyprland
    ];
    text = ''
      hyprctl dispatch exec "[workspace name:sunshine silent; monitor SUNSHINE] ${unstablePkgs.eden}/bin/eden -f -input-profile Moonlight '/nas/arr/ROMs/switch/Bluey the Videogame [01008C2019598000][v0].nsp'"
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      sunshine-create-display
      sunshine-remove-display
      sunshine-kill-eden
    ];

    # Grant the sunshine user service CAP_SYS_NICE (and nothing else) so it
    # can request the EGL high-priority GL context without warning:
    #   "EGL: context priority set to HIGH but CAP_SYS_NICE capability is
    #    missing"
    # systemd user services can't be granted capabilities directly, so we
    # attach them to the binary via `security.wrappers` (file caps) and let
    # the upstream sunshine module's `capSysAdmin` plumbing point ExecStart
    # at the wrapped binary in $wrapperDir.
    security.wrappers.sunshine.capabilities = lib.mkForce "cap_sys_nice+p";

    services.sunshine = {
      enable = true;
      autoStart = true;

      openFirewall = true;

      # Route the systemd user service through `security.wrappers.sunshine`
      # so the binary can carry file capabilities. The upstream module only
      # wires the wrapper into ExecStart when `capSysAdmin = true`, so we
      # enable it here and then strip back the capability set below to only
      # what we actually need (CAP_SYS_NICE for the EGL high-priority
      # context; CAP_SYS_ADMIN isn't required with the wlr capture backend).
      capSysAdmin = true;

      settings = {
        output_name = "SUNSHINE";
        origin_web_ui_allowed = "lan";
        gamepad = "xone";
        capture = "wlr";
        encoder = "vaapi";
        fec_percentage = 5;
        system_tray = 0;
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
            {
              do = "";
              undo = "${sunshine-kill-eden}/bin/sunshine-kill-eden";
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
            {
              do = "";
              undo = "${sunshine-kill-eden}/bin/sunshine-kill-eden";
            }
          ];
          auto-detach = "true";
        }
      ];
    };
  };
}

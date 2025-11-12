{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    system.stateVersion = "25.05"; # Version at install time, never change

    wsl.enable = true;
    wsl.defaultUser = "dirk";

    services = {
      openssh.enable = true;
    };

    environment.variables = {
      SSH_AUTH_SOCK = "/mnt/wsl/ssh-agent.sock";
    };

    systemd.user.services.ssh-agent-proxy = {
      description = "Windows SSH agent proxy";
      path = [ pkgs.wslu pkgs.coreutils pkgs.bash ];
      serviceConfig = {
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p /mnt/wsl"
          "${pkgs.coreutils}/bin/rm -f /mnt/wsl/ssh-agent.sock"
        ];
        ExecStart = "${pkgs.writeShellScript "ssh-agent-proxy" ''
          set -x  # Enable debug output

          # Get Windows username using wslvar
          WIN_USER="$("${pkgs.wslu}/bin/wslvar" USERNAME 2>/dev/null || echo $USER)"

          # Check common npiperelay locations
          NPIPE_PATHS=(
            "/mnt/c/Users/$WIN_USER/AppData/Local/Microsoft/WinGet/Packages/albertony.npiperelay_Microsoft.Winget.Source_8wekyb3d8bbwe/npiperelay.exe"
            "/mnt/c/Users/$WIN_USER/AppData/Local/Microsoft/WinGet/Links/npiperelay.exe"
          )

          NPIPE_PATH=""
          for path in "''${NPIPE_PATHS[@]}"; do
            echo "Checking npiperelay at: $path"
            if [ -f "$path" ]; then
              NPIPE_PATH="$path"
              break
            fi
          done

          if [ -z "$NPIPE_PATH" ]; then
            echo "npiperelay.exe not found in expected locations!"
            exit 1
          fi

          echo "Using npiperelay from: $NPIPE_PATH"

          exec ${pkgs.socat}/bin/socat -d UNIX-LISTEN:/mnt/wsl/ssh-agent.sock,fork,mode=600 \
            EXEC:"$NPIPE_PATH -ei -s //./pipe/openssh-ssh-agent",nofork
        ''}";
        Type = "simple";
        Restart = "always";
        RestartSec = "5";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      wantedBy = [ "default.target" ];
    };

    systemd.user.services.ssh-agent-proxy.serviceConfig.RuntimeDirectory = "ssh-agent";

    local = {
      user = {
        enable = true;
        name = "dirk";
        home-manager.enable = true;
        shell.package = pkgs.fish;
      };

      theme.preset = "everforest";

      system = {
        nix = {
          unfree.enable = true;
          nh.enable = true;
          ld.enable = true;
          flakes.enable = true;
        };

        utils = {
          dev = true;
          sysadmin = true;
        };
      };

      home-manager = {
        # keepassxc = {
        #   enable = true;
        #   databasePaths = [
        #     "/nas/ssd/secrets/Desktop.kdbx"
        #   ];
        #   keyfilePath = "/nas/secrets/desktop.key";
        # };
      };
    };
  };
}

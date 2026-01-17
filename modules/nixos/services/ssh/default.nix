{ lib, config, ... }:
let
  inherit (config.local) user;
  cfg = config.local.services.ssh;
in
{
  options.local.services.ssh = {
    enable = lib.mkEnableOption "Enable SSH server";

    disablePasswordAuth = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable password-based authentication (only allow key-based auth)";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${user.name}.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHrllPbgamZCEqQMn/cpM2cKoQKPS84DHX6q0Bej+M1F dirk"
    ];

    services = {
      openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = !cfg.disablePasswordAuth;
          KbdInteractiveAuthentication = !cfg.disablePasswordAuth;
        };
      };
    };

    programs.ssh.startAgent = true;
    security.pam.sshAgentAuth.enable = true;
  };
}

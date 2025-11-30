{ lib, config, ... }:
let
  inherit (config.local) user;
  cfg = config.local.services.ssh;
in
{
  options.local.services.ssh = {
    enable = lib.mkEnableOption "Enable SSH server";
  };

  config = lib.mkIf cfg.enable {
    users.users.${user.name}.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHrllPbgamZCEqQMn/cpM2cKoQKPS84DHX6q0Bej+M1F dirk"
    ];

    services = {
      openssh.enable = true;
    };

    programs.ssh.startAgent = true;
    security.pam.sshAgentAuth.enable = true;
  };
}

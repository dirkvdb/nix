{ pkgs, ... }:
let
  ioPressureSnapshot = pkgs.writeShellApplication {
    name = "io-pressure-snapshot";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      procps
      sysstat
      nfs-utils
    ];
    text = builtins.readFile ./io-pressure-snapshot.sh;
  };
in
{
  services.sysstat = {
    enable = true;
    collect-frequency = "*:00/1";
  };
  services.journald.extraConfig = ''
    SyncIntervalSec=30s
  '';

  # PID 1 feeds the hardware watchdog; a stalled recorder must not reboot the host.
  systemd.settings.Manager.RuntimeWatchdogSec = "1min";
  # Best effort only: EFI pstore needs working firmware and a kernel oops/panic.
  boot.kernelParams = [ "efi_pstore.pstore_disable=N" ];
  boot.kernel.sysctl = {
    "kernel.sysrq" = 24; # Diagnostic dumps and sync, not kill/reboot.
    "kernel.hung_task_timeout_secs" = 60;
    "kernel.hung_task_all_cpu_backtrace" = 1;
    "kernel.softlockup_all_cpu_backtrace" = 1;
    "kernel.hardlockup_all_cpu_backtrace" = 1;
  };

  systemd.services.io-pressure-snapshot = {
    description = "Quiet I/O pressure freeze snapshots";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${ioPressureSnapshot}/bin/io-pressure-snapshot";
      User = "root";
      UMask = "0077";
      Restart = "on-failure";
      RestartSec = "10s";
      Nice = 19;
      IOSchedulingClass = "idle";
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };
}

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.system.performance;
in
{
  options.local.system.performance = {
    enable = lib.mkEnableOption "Enable desktop performance/responsiveness settings";
  };

  config = lib.mkIf cfg.enable {
    # Automatically re-nice processes (games, compositors, etc.)
    # so the desktop stays responsive under load.
    services.ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
    };

    # Distribute hardware interrupts across all CPU cores
    # to avoid a single core becoming a bottleneck under load.
    services.irqbalance.enable = true;

    # Full preemption for lower desktop latency under load.
    boot.kernelParams = [ "preempt=full" ];
  };
}

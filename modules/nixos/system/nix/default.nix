{
  pkgs,
  ...
}:
{
  nix = {
    optimise.automatic = true;
  };

  environment.systemPackages = with pkgs; [
    nixfmt
    nix-output-monitor
  ];
}

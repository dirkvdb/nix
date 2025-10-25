{
  config,
  pkgs,
  ...
}:
{
  # enable containerization ( docker )
  virtualisation = {
    containers.enable = true;
    libvirtd = {
      enable = true;
    };
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };
}

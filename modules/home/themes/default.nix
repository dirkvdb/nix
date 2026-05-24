{
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.local) theme;
  mkUserHome = mkHome user.name;
in
{
  config = mkUserHome {
    xdg.dataFile."theme" = {
      source = ./${theme.name};
      recursive = true;
    };
  };
}

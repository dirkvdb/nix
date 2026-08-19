{
  lib,
  config,
  mkHome,
  unstablePkgs,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.lib.stylix) colors;
  cfg = config.local.apps.herdr;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.herdr = {
    enable = lib.mkEnableOption "Herdr terminal agent multiplexer";
  };

  # `herdr` isn't packaged in the pinned stable nixpkgs yet, so pull it from
  # unstablePkgs instead. Drop this once it lands on the stable channel.
  #
  # Stylix doesn't have a herdr target yet (see the "herdr: init" PR at
  # https://github.com/nix-community/stylix/pull/2455), so its color mapping
  # is reproduced here directly until that lands upstream.
  config = lib.mkIf cfg.enable (mkUserHome {
    programs.herdr = {
      enable = true;
      package = unstablePkgs.herdr;
      settings = {
        keys.prefix = "ctrl+s";
        ui = {
          sidebar_start_collapsed = true;
          sidebar_collapsed_mode = "hidden";
        };
        theme.custom = with colors.withHashtag; {
          accent = base0D;

          panel_bg = base00;
          surface_dim = base01;
          surface0 = base02;
          surface1 = base03;

          overlay0 = base03;
          overlay1 = base04;
          subtext0 = base04;
          text = base05;

          red = base08;
          peach = base09;
          yellow = base0A;
          green = base0B;
          teal = base0C;
          blue = base0D;
          mauve = base0E;
        };
      };
    };
  });
}

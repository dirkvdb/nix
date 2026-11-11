{
  lib,
  config,
  pkgs,
  mkHome,
  llmAgentsPkgs,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.lib.stylix) colors;
  cfg = config.local.apps.herdr;
  mkUserHome = mkHome user.name;
  jsonFormat = pkgs.formats.json { };
  themeFamily = builtins.fromJSON (builtins.readFile ../../../../configs/themes/charcoal-grove.json);
  charcoalGrove = lib.findFirst (
    variant: variant.appearance == "dark"
  ) (throw "herdr: Charcoal Grove dark palette is missing") themeFamily.themes;
  style = charcoalGrove.style;
  desktopTheme = jsonFormat.generate "herdr-charcoal-grove.json" {
    background = style."terminal.background";
    foreground = style."terminal.foreground";
    selection = style."element.selected";
    cursor = style.text;
    ansi = map (color: style."terminal.ansi.${color}") [
      "black"
      "red"
      "green"
      "yellow"
      "blue"
      "magenta"
      "cyan"
      "white"
      "bright_black"
      "bright_red"
      "bright_green"
      "bright_yellow"
      "bright_blue"
      "bright_magenta"
      "bright_cyan"
      "bright_white"
    ];
    colors = {
      foreground = style.text;
      surface = style."surface.background";
      canvas = style.background;
      chrome = style."panel.background";
      popover = style."elevated_surface.background";
      raised = style."element.background";
      hover = style."element.hover";
      selected = style."element.selected";
      border = style.border;
      input = style."border.selected";
      muted = style."text.muted";
      dim = style."text.disabled";
      accent = style."text.accent";
      accent_foreground = style.background;
      ring = style."border.focused";
      working = style.warning;
      blocked = style.error;
      done = style.success;
      idle = style."text.muted";
      unknown = style."text.disabled";
    };
  };
  desktopLook = jsonFormat.generate "herdr-stylix-look.json" {
    theme = "charcoal-grove";
    font = config.stylix.fonts.monospace.name;
    font_size = config.stylix.fonts.sizes.terminal;
    ui_font = config.stylix.fonts.sansSerif.name;
  };
  desktopLayout =
    pkgs.runCommand "herdr-charcoal-grove-layout.json" { nativeBuildInputs = [ pkgs.jq ]; }
      ''
        jq --slurpfile look ${desktopLook} '. + $look[0]' \
          ${llmAgentsPkgs.herdr-app.src}/defaults/layouts/main.json > "$out"
      '';
in
{
  options.local.apps.herdr = {
    enable = lib.mkEnableOption "Herdr terminal agent multiplexer";
  };

  # Herdr is maintained in the dedicated llm-agents.nix package set.
  #
  # Stylix doesn't have a herdr target yet (see the "herdr: init" PR at
  # https://github.com/nix-community/stylix/pull/2455), so its color mapping
  # is reproduced here directly until that lands upstream.
  config = lib.mkIf cfg.enable (mkUserHome {
    # The Herdr app uses `hc` on connected machines, including SSH remotes.
    home.packages = [
      llmAgentsPkgs.herdr-core
    ]
    ++ lib.optionals (config.local.desktop.enable or false) [ llmAgentsPkgs.herdr-app ];

    xdg.configFile = lib.mkIf (config.local.desktop.enable or false) {
      "herdr-app/themes/charcoal-grove.json".source = desktopTheme;
      # Herdr restores shipped layouts on startup; keep our look in a custom layout.
      "herdr-app/layouts/charcoal-grove.json".source = desktopLayout;
    };

    programs.herdr = {
      enable = true;
      package = llmAgentsPkgs.herdr;
      settings = {
        onboarding = false;
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

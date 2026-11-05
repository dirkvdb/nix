# Omarchy consumers share semantic roles and require six-digit RGB colors.
theme:
let
  inherit (theme) style;
in
{
  mode = theme.appearance;
}
// builtins.mapAttrs (_: color: builtins.substring 0 7 color) {
  background = style.background;
  # Preserve Flea's surface mapping; other consumers use lighter_background.
  dark_background = style."surface.background";
  darker_background = style."title_bar.inactive_background";
  lighter_background = style."elevated_surface.background";
  foreground = style.text;
  dark_foreground = style.ignored;
  light_foreground = style."editor.foreground";
  bright_foreground = style."terminal.bright_foreground";
  accent = style."text.accent";
  muted = style."text.muted";
  selection = style."element.selected";
  red = style.error;
  orange = style.conflict;
  yellow = style.warning;
  green = style.success;
  blue = style."terminal.ansi.blue";
  magenta = style.syntax.operator.color;
  cyan = style.info;
  brown = style.syntax.number.color;
  bright_red = style."terminal.ansi.bright_red";
  bright_yellow = style."terminal.ansi.bright_yellow";
  bright_green = style."terminal.ansi.bright_green";
  bright_cyan = style."terminal.ansi.bright_cyan";
  bright_blue = style."terminal.ansi.bright_blue";
  bright_magenta = style."terminal.ansi.bright_magenta";
}

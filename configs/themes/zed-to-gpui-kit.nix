# GPUI Kit uses different token names; all color values come from the Zed theme.
family:
let
  colorKeys = {
    "accent.background" = "element.selected";
    "accent.foreground" = "text";
    "background" = "background";
    "foreground" = "text";
    "border" = "border";
    "ring" = "text.accent";
    "input.border" = "border.focused";
    "link.foreground" = "syntax.link_text";
    "link.active.foreground" = "link_text.hover";
    "link.hover.foreground" = "link_text.hover";
    "list.active.background" = "element.selected";
    "list.active.border" = "border.selected";
    "list.hover.background" = "ghost_element.hover";
    "list.even.background" = "surface.background";
    "list.head.background" = "editor.subheader.background";
    "muted.background" = "surface.background";
    "muted.foreground" = "text.muted";
    "panel.background" = "panel.background";
    "popover.background" = "elevated_surface.background";
    "popover.foreground" = "text";
    "primary.background" = "text.accent";
    "primary.active.background" = "text.accent";
    "primary.hover.background" = "text.accent";
    "primary.foreground" = "editor.background";
    "scrollbar.background" = "scrollbar.track.background";
    "scrollbar.thumb.background" = "scrollbar.thumb.background";
    "secondary.background" = "element.background";
    "secondary.active.background" = "element.active";
    "secondary.hover.background" = "element.hover";
    "secondary.foreground" = "text";
    "tab.active.background" = "tab.active_background";
    "tab.active.foreground" = "text";
    "tab.background" = "tab.inactive_background";
    "tab.foreground" = "text.muted";
    "tab_bar.background" = "tab_bar.background";
    "title_bar.background" = "title_bar.background";
    "title_bar.border" = "border";
    "base.red" = "error";
    "base.green" = "success";
    "base.yellow" = "warning";
    "base.blue" = "terminal.ansi.blue";
    "base.magenta" = "syntax.operator";
    "base.cyan" = "info";
  };
  highlightKeys = [
    "editor.foreground"
    "editor.background"
    "editor.active_line.background"
    "editor.line_number"
    "editor.active_line_number"
    "editor.invisible"
    "syntax"
  ]
  ++
    builtins.concatMap
      (
        status:
        map (suffix: status + suffix) [
          ""
          ".background"
          ".border"
        ]
      )
      [
        "conflict"
        "created"
        "deleted"
        "error"
        "hidden"
        "hint"
        "ignored"
        "info"
        "modified"
        "predictive"
        "renamed"
        "success"
        "unreachable"
        "warning"
      ];
  convert =
    theme:
    let
      style = theme.style;
      colors = style // {

        "syntax.link_text" = style.syntax.link_text.color;
        "syntax.operator" = style.syntax.operator.color;
      };
    in
    {
      inherit (theme) name;
      mode = theme.appearance;
      colors = builtins.mapAttrs (_: key: colors.${key}) colorKeys;
      highlight = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = style.${name};
        }) (builtins.filter (name: builtins.hasAttr name style) highlightKeys)
      );
    };
in
{
  inherit (family) name author;
  themes = map convert family.themes;
}

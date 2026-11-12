# GitComet's GPUI frontend uses its own versioned theme schema, not GPUI Kit's.
family:
let
  convert =
    theme:
    let
      s = theme.style;
      # The shared palette's sand accent keeps controls warm without using yellow.
      uiAccent = builtins.elemAt s.accents 5;
      status = name: {
        foreground = s.${name};
        background = s."${name}.background";
        border = s."${name}.border";
      };
      diff = name: {
        foreground = s.${name};
        background = s."${name}.background";
        word_background = s."${name}.border";
        focused_background = s."${name}.border";
      };
      syntaxKeys = [
        "attribute"
        "boolean"
        "comment"
        "comment.doc"
        "constant"
        "constructor"
        "function"
        "keyword"
        "label"
        "namespace"
        "number"
        "operator"
        "preproc"
        "property"
        "punctuation"
        "punctuation.bracket"
        "punctuation.delimiter"
        "punctuation.list_marker"
        "punctuation.special"
        "string"
        "string.escape"
        "string.regex"
        "string.special"
        "tag"
        "text.literal"
        "type"
        "variable"
        "variable.special"
      ];
    in
    {
      inherit (theme) name appearance;
      key = if theme.appearance == "dark" then "charcoal_grove" else "charcoal_grove_light";
      colors = {
        surface = {
          canvas = s."editor.background";
          chrome = s."background";
          panel = s."panel.background";
          raised = s."elevated_surface.background";
          input = s."element.background";
        };
        foreground = {
          primary = s.text;
          secondary = s."text.muted";
          disabled = s."text.disabled";
          placeholder = s."text.placeholder";
          emphasis = s.text;
        };
        stroke = {
          subtle = s."border.variant";
          default = s.border;
          control = s."border.focused";
        };
        interaction = {
          hover_overlay = s."ghost_element.hover";
          pressed_overlay = s."ghost_element.active";
          hover_background = s."element.hover";
          pressed_background = s."element.active";
          selected_background = s."element.selected";
          selected_foreground = s.text;
          selected_indicator = s."border.selected";
          focus_ring = s."border.focused";
          focus_background = s."element.selected";
        };
        accent = {
          foreground = uiAccent;
          solid = uiAccent;
          on_solid = s."editor.background";
          subtle_background = s."element.selected";
        };
        status = {
          info = status "info";
          success = status "success";
          warning = status "warning";
          danger = status "error";
        };
        editor = {
          background = s."editor.background";
          foreground = s."editor.foreground";
          gutter_background = s."editor.gutter.background";
          line_number = s."editor.line_number";
          cursor = (builtins.head s.players).cursor;
          selection_background = (builtins.head s.players).selection;
          search_match_background = s."search.match_background";
          search_match_foreground = s.text;
          bracket_match_background =
            s."editor.document_highlight.bracket_background" or s."editor.document_highlight.read_background";
          occurrence_highlight_background = s."editor.document_highlight.read_background";
          indent_guide = s."editor.indent_guide" or s."editor.wrap_guide";
        };
        diff = {
          added = diff "created";
          removed = diff "deleted";
          modified = diff "modified";
        };
        tooltip = {
          background = s."elevated_surface.background";
          foreground = s.text;
        };
        scrollbar = {
          thumb = s."scrollbar.thumb.background";
          thumb_hover = s."scrollbar.thumb.hover_background";
          thumb_pressed = s."scrollbar.thumb.hover_background";
        };
        shadow = s."border.transparent";
        # Keep the main graph lane consistent with the subdued UI accent.
        graph_lane_palette = [
          uiAccent
        ]
        ++ builtins.filter (color: color != uiAccent) s.accents;
      };
      syntax = builtins.listToAttrs (
        map (name: {
          name = builtins.replaceStrings [ "." ] [ "_" ] name;
          value = s.syntax.${name}.color;
        }) syntaxKeys
      );
      radii = {
        panel = 8;
        pill = 999;
        row = 4;
        control = 8;
        popover = 10;
        window = 12;
      };
    };
in
{
  schema_version = 2;
  inherit (family) name author;
  themes = map convert family.themes;
}

{ ... }:
{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      palette = "default";

      format = ''[╭](fg:separator)$status$hostname$directory$cmd_duration$line_break[╰](fg:separator)$character'';

      palettes.default = {
        prompt_ok = "#c3e88d";
        prompt_err = "#ff757f";
        icon = "#161514";
        separator = "#737aa2";
        background = "#414868";
        host = "#7dcfff";
        directory = "#7aa83e";
        duration = "#ffc777";
        status = "#c53b53";
      };

      character = {
        success_symbol = "[❯](fg:prompt_ok)";
        error_symbol = "[❯](fg:prompt_err)";
      };

      directory = {
        format = "[─](fg:separator)[](fg:directory)[](fg:icon bg:directory)[](fg:directory bg:background)[ $path](bg:background)[](fg:background)";
        truncate_to_repo = false;
        truncation_length = 0;
      };

      status = {
        format = "[─](fg:separator)[](fg:status)[](fg:icon bg:status)[](fg:status bg:background)[ $status](bg:background)[](fg:background)";
        pipestatus = true;
        pipestatus_separator = "-";
        pipestatus_segment_format = "$status";
        pipestatus_format = ''[─](fg:separator)[](fg:status)[\\uf658](fg:icon bg:status)[](fg:status bg:background)[ $pipestatus](bg:background)[](fg:background)'';
        disabled = false;
      };

      cmd_duration = {
        format = "[─](fg:separator)[](fg:duration)[󱐋](fg:icon bg:duration)[](fg:duration bg:background)[ $duration](bg:background)[](fg:background)";
        min_time = 1000;
      };

      hostname = {
        ssh_only = true;
        format = "[─](fg:separator)[](fg:host)[󰍹](fg:icon bg:host)[](fg:host bg:background)[ $hostname](bg:background)[](fg:background)";
        disabled = false;
      };

      time = {
        format = "[](fg:duration)[󰥔](fg:icon bg:duration)[](fg:duration bg:background)[ $time](bg:background)[](fg:background)";
        disabled = false;
      };
    };
  };
}

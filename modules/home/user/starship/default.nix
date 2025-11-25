{ config, ... }:
let
  inherit (config.local) user;
  inherit (config.lib.stylix) colors;
in
{
  home-manager.users.${user.name} = {
    stylix.targets.starship.enable = false;

    programs.starship = {
      enable = true;
      settings = {
        add_newline = false;
        palette = "default";

        format = ''[╭](fg:separator)$status$hostname$custom$directory$git_branch$nix_shell$cmd_duration$line_break[╰](fg:separator)$character'';

        palettes.default = {
          prompt_ok = "#${colors.base0B}";
          prompt_err = "#${colors.base08}";
          icon = "#${colors.base00}";
          background = "#${colors.base03}";
          separator = "#${colors.base03}";
          host = "#${colors.base0D}";
          directory = "#${colors.base06}";
          nixshell = "#${colors.base0E}";
          gitbranch = "#${colors.base05}";
          duration = "#${colors.base0A}";
          status = "#${colors.base0F}";
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

        nix_shell = {
          format = "[─](fg:separator)[](fg:nixshell)[](fg:icon bg:nixshell)[](fg:nixshell bg:background)[ $name$state](bg:background)[](fg:background)";
          impure_msg = "";
          pure_msg = " [impure](bold green bg:background)";
          disabled = false;
        };

        git_branch = {
          format = "[─](fg:separator)[](fg:gitbranch)[](fg:icon bg:gitbranch)[](fg:gitbranch bg:background)[ $branch](bg:background)[](fg:background)";
          style = "italic cyan";
        };

        git_status = {
          format = "[─](fg:separator)[](fg:status)[](fg:icon bg:status)[](fg:status bg:background)[ $all_status]($style)(bg:background)[](fg:background)";
          style = "cyan";
          ahead = "⇡\${count} ";
          diverged = "⇕⇡\${ahead_count}⇣\${behind_count} ";
          behind = "⇣\${count} ";
          conflicted = " ";
          up_to_date = " ";
          untracked = "? ";
          modified = " ";
          stashed = "";
          staged = "";
          renamed = "";
          deleted = "";
        };

        status = {
          format = "[─](fg:separator)[](fg:status)[](fg:icon bg:status)[](fg:status bg:background)[ $status](bg:background)[](fg:background)";
          pipestatus = true;
          pipestatus_separator = "-";
          pipestatus_segment_format = "$status";
          pipestatus_format = ''[─](fg:separator)[](fg:status)[](fg:icon bg:status)[](fg:status bg:background)[ $pipestatus](bg:background)[](fg:background)'';
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

        custom.wsl = {
          when = ''[ -n "$WSL_DISTRO_NAME" ]'';
          format = "[─](fg:separator)[](fg:host)[](fg:icon bg:host)[](fg:host bg:background)[ WSL](bg:background)[](fg:background)";
        };

        time = {
          format = "[](fg:duration)[󰥔](fg:icon bg:duration)[](fg:duration bg:background)[ $time](bg:background)[](fg:background)";
          disabled = false;
        };
      };
    };
  };
}

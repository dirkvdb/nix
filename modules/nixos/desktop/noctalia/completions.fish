# Fish completions for the `noctalia` CLI (https://noctalia.dev).
#
# Upstream doesn't ship a completion generator or shell completion scripts, so
# this is maintained by hand. `noctalia msg <command>` is the exception: that
# command set is registered internally by the running shell and changes
# across releases, so it's fetched live via `noctalia msg --help` instead of
# being hard-coded here.

function __noctalia_msg_commands --description 'List noctalia msg subcommands from the running instance'
    for line in (noctalia msg --help 2>/dev/null)
        string match -qr '^  \S' -- $line; or continue
        set -l cmd (string replace -r '^  (\S+).*' '$1' -- $line)
        set -l desc (string trim (string replace -r '^  \S+' '' -- $line))
        if test -n "$desc"
            printf '%s\t%s\n' $cmd $desc
        else
            printf '%s\n' $cmd
        end
    end
end

function __noctalia_msg_next_is_command --description 'True right after `noctalia msg`, before a command is typed'
    set -l toks (commandline -opc)
    test (count $toks) -eq 2 -a "$toks[2]" = msg
end

# No filename completion by default; only enabled where an argument expects a path.
complete -c noctalia -f

# Top-level subcommands and flags (only before one is chosen)
complete -c noctalia -n __fish_use_subcommand -a msg -d 'Send a command to the running instance'
complete -c noctalia -n __fish_use_subcommand -a theme -d 'Generate a color palette from an image'
complete -c noctalia -n __fish_use_subcommand -a config -d 'Validate config and support/replay helpers'
complete -c noctalia -n __fish_use_subcommand -a dmenu -d 'Pipe stdin items into the launcher'
complete -c noctalia -n __fish_use_subcommand -a plugins -d 'Offline plugin author tools (lint)'
complete -c noctalia -n __fish_use_subcommand -a firefox-theme -d 'Firefox theme host helpers (Pywalfox-compatible)'
complete -c noctalia -n __fish_use_subcommand -s h -l help -d 'Show help'
complete -c noctalia -n __fish_use_subcommand -s v -l version -d 'Show version'
complete -c noctalia -n __fish_use_subcommand -s d -l daemon -d 'Run in background'

# `noctalia msg <command>` — dynamic, queried from the running instance
complete -c noctalia -n __noctalia_msg_next_is_command -a '(__noctalia_msg_commands)'
complete -c noctalia -n __noctalia_msg_next_is_command -l help -d 'List available msg commands'

# `noctalia theme <image> [options]`
complete -c noctalia -n "__fish_seen_subcommand_from theme" -l scheme -d 'Palette scheme' -xa 'm3-tonal-spot m3-content m3-fruit-salad m3-rainbow m3-monochrome vibrant faithful soft dysfunctional muted'
complete -c noctalia -n "__fish_seen_subcommand_from theme" -l dark -d 'Emit only the dark variant (default)'
complete -c noctalia -n "__fish_seen_subcommand_from theme" -l light -d 'Emit only the light variant'
complete -c noctalia -n "__fish_seen_subcommand_from theme" -l both -d 'Emit both variants under dark/light keys'
complete -c noctalia -n "__fish_seen_subcommand_from theme" -l pure-black -d 'Re-anchor the dark surface ramp to true black (OLED)'
complete -c noctalia -n "__fish_seen_subcommand_from theme" -l theme-json -d 'Load precomputed dark/light token maps from JSON' -rF
complete -c noctalia -n "__fish_seen_subcommand_from theme" -s o -d 'Write JSON to file instead of stdout' -rF
complete -c noctalia -n "__fish_seen_subcommand_from theme" -s r -l render -d 'Render a template file to an output path (in:out)'
complete -c noctalia -n "__fish_seen_subcommand_from theme" -s c -l config -d 'Process a TOML template config file' -rF
complete -c noctalia -n "__fish_seen_subcommand_from theme" -l builtin-config -d 'Process the shipped built-in template catalog'
complete -c noctalia -n "__fish_seen_subcommand_from theme" -l list-templates -d 'List built-in, cached community, and configured user templates'
complete -c noctalia -n "__fish_seen_subcommand_from theme" -l default-mode -d 'Template default mode' -xa 'dark light'
complete -c noctalia -n "__fish_seen_subcommand_from theme" -l help -d 'Show help'
complete -c noctalia -n "__fish_seen_subcommand_from theme" -rF -d 'Source image'

# `noctalia config <command> [options]`
complete -c noctalia -n "__fish_seen_subcommand_from config; and not __fish_seen_subcommand_from validate export settings-count replay-report" -a validate -d 'Check config validity'
complete -c noctalia -n "__fish_seen_subcommand_from config; and not __fish_seen_subcommand_from validate export settings-count replay-report" -a export -d 'Print the active config as TOML'
complete -c noctalia -n "__fish_seen_subcommand_from config; and not __fish_seen_subcommand_from validate export settings-count replay-report" -a settings-count -d 'Count Settings UI controls'
complete -c noctalia -n "__fish_seen_subcommand_from config; and not __fish_seen_subcommand_from validate export settings-count replay-report" -a replay-report -d 'Reconstruct config/state dirs from a support report'
complete -c noctalia -n "__fish_seen_subcommand_from config; and __fish_seen_subcommand_from validate" -rF
complete -c noctalia -n "__fish_seen_subcommand_from config; and __fish_seen_subcommand_from export" -xa 'merged full'
complete -c noctalia -n "__fish_seen_subcommand_from config; and __fish_seen_subcommand_from replay-report" -l target -d 'Directory to write replay files' -rF
complete -c noctalia -n "__fish_seen_subcommand_from config; and __fish_seen_subcommand_from replay-report" -l flattened -d 'Write only the merged config as config.toml'
complete -c noctalia -n "__fish_seen_subcommand_from config; and __fish_seen_subcommand_from replay-report" -l force -d 'Remove an existing target directory before writing'
complete -c noctalia -n "__fish_seen_subcommand_from config; and __fish_seen_subcommand_from replay-report" -rF

# `noctalia plugins <command> [paths]`
complete -c noctalia -n "__fish_seen_subcommand_from plugins; and not __fish_seen_subcommand_from lint" -a lint -d "Cross-check plugin settings against getConfig() calls"
complete -c noctalia -n "__fish_seen_subcommand_from plugins; and __fish_seen_subcommand_from lint" -rF

# `noctalia dmenu [-p prompt]`
complete -c noctalia -n "__fish_seen_subcommand_from dmenu" -s p -l prompt -d 'Prompt text' -x

# `noctalia firefox-theme <action>`
complete -c noctalia -n "__fish_seen_subcommand_from firefox-theme" -a host -d 'Run as Firefox native messaging host'
complete -c noctalia -n "__fish_seen_subcommand_from firefox-theme" -a install -d 'Install user-local native messaging manifest'
complete -c noctalia -n "__fish_seen_subcommand_from firefox-theme" -a uninstall -d 'Remove user-local native messaging manifest'
complete -c noctalia -n "__fish_seen_subcommand_from firefox-theme" -a update -d 'Ask all running hosts to push colors'
complete -c noctalia -n "__fish_seen_subcommand_from firefox-theme" -a dark -d 'Persist and push dark theme mode'
complete -c noctalia -n "__fish_seen_subcommand_from firefox-theme" -a light -d 'Persist and push light theme mode'
complete -c noctalia -n "__fish_seen_subcommand_from firefox-theme" -a auto -d 'Persist and push auto theme mode'

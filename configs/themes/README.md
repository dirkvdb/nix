# Charcoal Grove

`charcoal-grove.json` is the single source of truth for the Charcoal Grove
theme family used by Zed, topq, Map, and Omasend. Edit this file to change their
palettes or syntax highlighting. It contains Charcoal Grove (dark) and
Charcoal Grove Light.

Zed installs the JSON directly. The topq and Map modules generate GPUI Kit JSON
using `zed-to-gpui-kit.nix`, which maps UI token names and copies syntax
highlighting and supported editor/status colors. The adapter contains no
separate palette. App-specific controls reuse the closest shared color role.

Zed, topq, Map, and Omasend select Charcoal Grove for dark mode and Charcoal
Grove Light for light mode. Zed retains its dark-mode default; topq, Map, and
Omasend retain their system-following defaults.

Omasend's package generates Rust `gpui_omarchy::Theme` palettes from both shared
variants and embeds them in the executable. Its Light and Dark choices apply
the corresponding variant, and System follows the window appearance, including
changes on Linux. The library's platform-specific font defaults are retained;
no external Omarchy installation or theme file is required.

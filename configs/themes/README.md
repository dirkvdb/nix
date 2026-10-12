# Charcoal Grove

`charcoal-grove.json` is the single source of truth for the Charcoal Grove
theme used by Zed and topq. Edit this file to change either application's palette
or syntax highlighting. There is no custom light variant.

Zed installs the JSON directly. Topq's module generates GPUI Kit JSON using
`zed-to-gpui-kit.nix`, which maps UI token names and copies syntax highlighting
and supported editor/status colors. The adapter contains no separate palette.
Topq-specific controls reuse the closest shared color role.

Both applications select Charcoal Grove for dark mode and Charcoal Grove Light
for light mode. Zed retains its dark-mode default; topq retains its
system-following default.

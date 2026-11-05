# Charcoal Grove

`charcoal-grove.json` is the single source of truth for the Charcoal Grove
theme family used by Zed, topq, Map, Omasend, and Flea. Edit this file to change
their palettes or syntax highlighting. It contains Charcoal Grove (dark) and
Charcoal Grove Light.

Zed installs the JSON directly. The topq and Map modules generate GPUI Kit JSON
using `zed-to-gpui-kit.nix`, which maps UI token names and copies syntax
highlighting and supported editor/status colors. The adapter contains no
separate palette. App-specific controls reuse the closest shared color role.

Zed, topq, and Map select Charcoal Grove for dark mode and Charcoal Grove Light
for light mode. Zed retains its dark-mode default; topq and Map retain their
system-following defaults.

On Linux desktops, Home Manager maps the dark variant to Omarchy's semantic
palette using `zed-to-omarchy.nix` and installs:

- `~/.local/state/omarchy/current/theme/colors.toml`
- `~/.local/state/omarchy/current/theme.name`

Flea, Omasend, and other applications that read the current Omarchy palette discover it
at this standard location without application-specific theme patches or
environment overrides. The adapter includes the standard semantic and bright
color roles, explicit dark mode, and six-digit RGB values for compatibility
with strict consumers. These paths are intentionally independent of
`XDG_STATE_HOME`, matching upstream discovery. Home Manager owns the current
palette; a separate Omarchy theme switcher should not manage the same files.

Omasend uses its upstream System theme mode (the default) to read and follow the
shared Omarchy palette on Linux. It no longer embeds custom palettes or requires
a theme patch. If a previous session saved Light or Dark, select System in
Omasend's theme menu. Explicit Light and Dark use upstream Flexoki Light and Tokyo
Night respectively; System follows the generated dark palette rather than the
window appearance.

This does not install Omarchy or its per-application theme templates. Applications
must support reading the shared palette.

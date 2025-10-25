local wezterm = require 'wezterm'
local config = wezterm.config_builder()


config.set_environment_variables = {
  XDG_CONFIG_HOME = wezterm.home_dir .. '/.config',
}


--config.color_scheme = 'Tokyo Night'
config.color_scheme = 'Tokyo Night Moon'
config.font = wezterm.font('FiraMono Nerd Font Mono', { weight = 'Bold' })
--config.font = wezterm.font('CaskaydiaMono Nerd Font', { weight = 'Bold' })
config.font_size = 14
config.enable_scroll_bar = true
config.scrollback_lines = 100000
config.initial_cols = 100
--config.window_decorations = 'RESIZE'
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.native_macos_fullscreen_mode = true
config.window_close_confirmation = 'NeverPrompt'

return config

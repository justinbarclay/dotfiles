-- Pull in the wezterm API
local wezterm = require 'wezterm'
local default_font_size = 16
-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices
config.audible_bell = 'Disabled'
config.automatically_reload_config = true
config.tab_bar_at_bottom = true
config.window_decorations = 'RESIZE'
config.window_frame = {
  -- The font used in the tab bar.
  -- Roboto Bold is the default; this font is bundled
  -- with wezterm.
  -- Whatever font is selected here, it will have the
  -- main font setting appended to it to pick up any
  -- fallback fonts you may have used there.
  font = wezterm.font { family = 'Menlo' },

  -- The size of the font in the tab bar.
  -- Default to 10.0 on Windows but 12.0 on other systems
  font_size = default_font_size,
}
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
   config.default_prog = { 'nu', '-l' }
end
config.font = wezterm.font_with_fallback {
  'CaskaydiaCove Nerd Font Mono',
}
config.font_size = default_font_size;

config.front_end = 'WebGpu';
-- For example, changing the color scheme:
config.color_scheme = 'Laserwave (Gogh)'

-- and finally, return the configuration to wezterm
return config

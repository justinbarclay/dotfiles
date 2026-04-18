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

-- Windows-specific configuration
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  -- Open new tabs/windows inside WSL by default instead of cmd/PowerShell
  config.default_prog = { 'nu', '-l' }
  config.default_domain = 'WSL:NixOS'

  -- Quick-launch menu so you can still reach PowerShell or a bare Nu session
  config.launch_menu = {
    { label = 'NixOS WSL (nu)',  domain = { DomainName = 'WSL:NixOS' },  args = { 'nu', '-l' } },
    { label = 'PowerShell',      args = { 'pwsh', '-NoLogo' } },
    { label = 'Nushell (native)', args = { 'nu', '-l' } },
  }

  -- Prefer the Nerd Font installed by Scoop; fall back to the Cascadia variants
  -- that ship with Windows Terminal / VS Code so there is always a fallback.
  config.font = wezterm.font_with_fallback {
    'CaskaydiaMono Nerd Font',
    'CaskaydiaMono NF',
    'Cascadia Code NF',
    'Cascadia Mono NF',
  }
else
  config.font = wezterm.font_with_fallback {
    'CaskaydiaMono Nerd Font',
  }
end

config.font_size = default_font_size;

config.front_end = 'WebGpu';
-- For example, changing the color scheme:
config.color_scheme = 'Laserwave (Gogh)'

-- and finally, return the configuration to wezterm
return config

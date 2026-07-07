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
  config.default_ssh_auth_sock = "\\\\.\\pipe\\openssh-ssh-agent"
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
-- Kusanagi theme ported from https://github.com/LionyxML/kusanagi-theme
config.color_schemes = {
  ['Kusanagi'] = {
    foreground    = '#68b8cc',
    background    = '#050810',
    cursor_bg     = '#00e5ff',
    cursor_fg     = '#050810',
    cursor_border = '#00e5ff',
    selection_fg  = '#050810',
    selection_bg  = '#0d2840',
    scrollbar_thumb = '#2d5a70',
    split         = '#2d5a70',

    ansi = {
      '#080c16', -- black      (bg-deep)
      '#ff0044', -- red        (hot-pink / errors)
      '#00cc77', -- green      (neon-green / strings)
      '#ffaa00', -- yellow     (amber / warnings)
      '#00b8cc', -- blue       (cyan-deep)
      '#cc55ff', -- magenta    (purple / keywords)
      '#00e5ff', -- cyan       (neon-cyan / builtins)
      '#68b8cc', -- white      (fg-main)
    },
    brights = {
      '#1a3a50', -- bright black   (teal-faint)
      '#ff4466', -- bright red     (pink-soft)
      '#00cc77', -- bright green   (neon-green)
      '#ffaa00', -- bright yellow  (amber)
      '#00c5dd', -- bright blue    (cyan-soft)
      '#cc55ff', -- bright magenta (purple)
      '#00e5ff', -- bright cyan    (neon-cyan)
      '#8ecede', -- bright white   (teal-soft)
    },

    tab_bar = {
      background = '#080c16',
      active_tab = {
        bg_color = '#080c16',
        fg_color = '#68b8cc',
      },
      inactive_tab = {
        bg_color = '#0a1628',
        fg_color = '#2d5a70',
      },
      inactive_tab_hover = {
        bg_color = '#0d2030',
        fg_color = '#00c5dd',
      },
      new_tab = {
        bg_color = '#080c16',
        fg_color = '#2d5a70',
      },
      new_tab_hover = {
        bg_color = '#0d2030',
        fg_color = '#00e5ff',
      },
    },
  },
}
config.color_scheme = 'Kusanagi'

-- and finally, return the configuration to wezterm
return config

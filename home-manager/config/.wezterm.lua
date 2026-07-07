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
config.scrollback_lines = 10000
config.use_fancy_tab_bar = true
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false

config.window_frame = {
  font = wezterm.font { family = 'Menlo' },
  font_size = default_font_size,
  inactive_titlebar_bg = 'none',
  active_titlebar_bg = 'none',
}

config.colors = {
  tab_bar = {
    inactive_tab_edge = 'none',
  },
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

-- Helper function to get clean process name
local function get_process_name(pane)
  local name = pane.foreground_process_name
  if not name or name == "" then
    return ""
  end
  -- Extract last segment of process path
  name = name:gsub("(.*)/", "")
  name = name:gsub("(.*)\\", "") -- handle Windows paths
  name = name:gsub("%.exe$", "")
  return name
end

-- Helper function to get clean directory path
local function get_current_dir(pane)
  local uri = pane.current_working_dir
  if not uri then
    return ""
  end
  local path = uri.path
  if not path then
    return ""
  end

  -- Replace home directory with ~
  local home = os.getenv("HOME") or os.getenv("USERPROFILE")
  if home then
    -- escape special characters in home path for pattern matching
    local pattern = "^" .. home:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    path = path:gsub(pattern, "~")
  end
  return path
end

local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

wezterm.on('format-tab-title', function(tab, tabs, panes, config_obj, hover, max_width)
  local background = '#1a3a50' -- inactive_tab bg (dark slate-blue)
  local foreground = '#68b8cc' -- inactive_tab fg (light cyan-blue)
  local edge_background = 'none'
  local edge_foreground = background

  if tab.is_active then
    background = '#00e5ff' -- active_tab bg (neon cyan)
    foreground = '#050810' -- active_tab fg (deep black-blue)
    edge_foreground = background
  elseif hover then
    background = '#2d5a70' -- inactive_tab_hover bg (teal-deep)
    foreground = '#00e5ff' -- inactive_tab_hover fg (neon cyan)
    edge_foreground = background
  end

  local pane = tab.active_pane
  local process = get_process_name(pane)
  local dir = get_current_dir(pane)

  -- Keep directory short: just show the last segment or full path if short
  local dir_name = dir
  if dir_name ~= "~" and dir_name ~= "/" then
    dir_name = dir_name:gsub("(.*)/", "")
    dir_name = dir_name:gsub("(.*)\\", "")
  end

  local title_str = ""
  if process ~= "" then
    title_str = string.format("%s (%s)", dir_name, process)
  else
    title_str = dir_name
  end

  local title = "   " .. wezterm.truncate_right(title_str, max_width - 1) .. "   "

  return {
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_RIGHT_ARROW },
  }
end)

wezterm.on('update-status', function(window, pane)
  local workspace = window:active_workspace()
  local cells = {}

  -- Include workspace
  table.insert(cells, { text = " " .. workspace .. " ", fg = "#00cc77" })

  -- Include current mode / key table if any
  local key_table = window:active_key_table()
  if key_table then
    table.insert(cells, { text = " KEY: " .. key_table .. " ", fg = "#ffaa00" })
  end

  -- Include current time
  local time = wezterm.strftime('%H:%M')
  table.insert(cells, { text = " " .. time .. " ", fg = "#cc55ff" })

  local status_items = {}
  local bg = 'none'
  local separator_fg = '#2d5a70'

  for i, cell in ipairs(cells) do
    if i > 1 then
      table.insert(status_items, { Background = { Color = bg } })
      table.insert(status_items, { Foreground = { Color = separator_fg } })
      table.insert(status_items, { Text = "│" })
    end

    table.insert(status_items, { Background = { Color = bg } })
    table.insert(status_items, { Foreground = { Color = cell.fg } })
    table.insert(status_items, { Text = cell.text })
  end

  window:set_right_status(wezterm.format(status_items))
end)

-- and finally, return the configuration to wezterm
return config

-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

local right_click_clipboard = wezterm.action_callback(function(window, pane)
  local has_selection = window:get_selection_text_for_pane(pane) ~= ''

  if has_selection then
    window:perform_action(act.CopyTo 'ClipboardAndPrimarySelection', pane)
    window:perform_action(act.ClearSelection, pane)
    return
  end

  window:perform_action(act.PasteFrom 'Clipboard', pane)
end)

-- Exact RGB palette matching Konsole's catppuccin-frappe.colorscheme
config.colors = {
  foreground = '#c6d0f5',
  background = '#303446',
  cursor_bg = '#f2d5cf',
  cursor_border = '#f2d5cf',
  cursor_fg = '#303446',
  selection_bg = '#626880',
  selection_fg = '#c6d0f5',

  ansi = {
    '#737994', -- Black
    '#e78284', -- Red
    '#a6d189', -- Green
    '#e5c890', -- Yellow
    '#8caaee', -- Blue
    '#ca9ee6', -- Magenta
    '#99d1db', -- Cyan (Exact Konsole #99D1DB)
    '#c6d0f5', -- White
  },
  brights = {
    '#737994', -- Bright Black
    '#e78284', -- Bright Red
    '#a6d189', -- Bright Green
    '#e5c890', -- Bright Yellow
    '#8caaee', -- Bright Blue
    '#ca9ee6', -- Bright Magenta
    '#99d1db', -- Bright Cyan (#99D1DB)
    '#c6d0f5', -- Bright White
  },
}

config.bold_brightens_ansi_colors = "No"

config.default_cursor_style = 'SteadyBar'
config.enable_scroll_bar = false
config.enable_tab_bar = false
config.font = wezterm.font 'MesloLGL Nerd Font Mono'
config.font_size = 10.5
config.initial_cols = 150
config.initial_rows = 40
config.window_background_opacity = 1.0
config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }

config.keys = {
    -- Make terminal-side clipboard shortcuts explicit for TUIs like Codex.
    { key = 'C', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
    { key = 'V', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },
    { key = 'Insert', mods = 'CTRL', action = act.CopyTo 'PrimarySelection' },
    { key = 'Insert', mods = 'SHIFT', action = act.PasteFrom 'PrimarySelection' },
}

config.mouse_bindings = {
    -- Bind 'Up' event of CTRL-Click to open hyperlinks
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
    },
    -- Disable the 'Down' event of CTRL-Click to avoid weird program behaviors
    {
      event = { Down = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.Nop,
    },
    -- Right click copies the current selection, otherwise it pastes.
    {
      event = { Up = { streak = 1, button = 'Right' } },
      mods = 'NONE',
      action = right_click_clipboard,
    },
    {
      event = { Down = { streak = 1, button = 'Right' } },
      mods = 'NONE',
      action = act.Nop,
    },
  }

-- Return the configuration to wezterm
return config

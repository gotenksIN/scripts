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

-- This is where you actually apply your config choices
config.color_scheme = 'Dracula (Official)'
config.default_cursor_style = 'SteadyBar'
config.enable_scroll_bar=true
config.enable_tab_bar = false
config.font = wezterm.font 'MesloLGS Nerd Font'
config.font_size = 10.5
config.initial_cols = 150
config.initial_rows = 40
config.window_background_opacity = 0.85
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
-- and finally, return the configuration to wezterm
return config

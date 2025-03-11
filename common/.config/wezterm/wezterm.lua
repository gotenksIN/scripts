-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

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
  }
-- and finally, return the configuration to wezterm
return config

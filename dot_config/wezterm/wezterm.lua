local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux
local config = wezterm.config_builder()

require('modules.theme_picker').apply_to_config(config)

-- ═══ SHELL ═══
local is_win = wezterm.target_triple:find('windows') ~= nil

if is_win then
  config.default_prog = { 'C:/msys64/usr/bin/bash.exe', '-l' }
  config.set_environment_variables = {
    MSYSTEM = 'UCRT64',
    CHERE_INVOKING = '1',
  }
  config.win32_system_backdrop = 'Acrylic'
else
  config.default_prog = { '/bin/bash', '-l' }
end


config.launch_menu = {
  { label = 'UCRT64',  args = { 'C:/msys64/usr/bin/bash.exe', '-l' } },
  { label = 'PowerShell', args = { 'pwsh.exe', '-NoLogo' } },
  { label = 'cmd',     args = { 'cmd.exe' } },
}


-- ═══ GÖRÜNÜM ═══
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_close_confirmation = 'NeverPrompt'


-- Win11'de acrylic blur. Win10'daysan bu satırı sil, opacity yeter.
config.window_background_opacity = 0.92

-- ═══ FONT ═══
config.font = wezterm.font_with_fallback {
  { family = 'JetBrains Mono', weight = 'Medium' },
  'Symbols Nerd Font Mono',
  'Segoe UI Emoji',
}
config.font_size = 11.0
config.line_height = 1.1
-- Ligature sevmiyorsan: calt=0, liga=0
config.harfbuzz_features = { 'calt=1', 'liga=1', 'clig=1', 'ss01=1' }

-- ═══ PERFORMANS ═══
config.front_end = 'WebGpu'
config.webgpu_power_preference = 'HighPerformance'
config.max_fps = 144
config.animation_fps = 60
config.scrollback_lines = 50000

-- ═══ CURSOR & BELL ═══
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'
config.audible_bell = 'Disabled'

-- Alt+1..9 -> tab
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i), mods = 'ALT', action = act.ActivateTab(i - 1),
  })
end

-- ═══ MOUSE ═══
config.mouse_bindings = {
  -- Ctrl+Click -> link aç
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'CTRL',
    action = act.OpenLinkAtMouseCursor },
  -- Sag tik -> yapistir
  { event = { Down = { streak = 1, button = 'Right' } }, mods = 'NONE',
    action = act.PasteFrom 'Clipboard' },
}

 

-- ═══ MAXIMIZE ON START ═══
wezterm.on('gui-startup', function(cmd)
  local _, _, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)
 
config.debug_key_events = true


-- ═══ KEYBINDS ═══
config.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1000 }
config.keys = {
  -- Split
  { key = '\\', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-',  mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'x',  mods = 'LEADER', action = act.CloseCurrentPane { confirm = false } },
  { key = 'z',  mods = 'LEADER', action = act.TogglePaneZoomState },

  -- Pane gezinme (vim style)
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

  -- Pane resize
  { key = 'LeftArrow',  mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'RightArrow', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },
  { key = 'UpArrow',    mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Up', 3 } },
  { key = 'DownArrow',  mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Down', 3 } },

  -- Tab
  { key = 't', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
  { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
  { key = 'r', mods = 'LEADER', action = act.PromptInputLine {
      description = 'Tab adi:',
      action = wezterm.action_callback(function(win, _, line)
        if line then win:active_tab():set_title(line) end
      end),
  }},

  -- Launcher / workspace
{ key = 'w', mods = 'LEADER', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES|LAUNCH_MENU_ITEMS' } },
  -- Ekran temizle (scrollback dahil)
  { key = 'k', mods = 'CTRL|SHIFT', action = act.ClearScrollback 'ScrollbackAndViewport' },

  -- Quick select / copy mode
  { key = 'Space', mods = 'CTRL|SHIFT', action = act.QuickSelect },
  { key = 'f',     mods = 'CTRL|SHIFT', action = act.Search { CaseInSensitiveString = '' } },

  -- Font zoom
  { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = act.ResetFontSize },
}



require('modules.status').apply_to_config(config)


return config

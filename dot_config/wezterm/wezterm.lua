local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux
local config = wezterm.config_builder()

require('modules.theme_picker').apply_to_config(config)

-- ═══ SHELL / PLATFORM ═══
local is_win = wezterm.target_triple:find('windows') ~= nil

if is_win then
  config.default_prog = { 'C:/msys64/usr/bin/bash.exe', '-l' }
  config.set_environment_variables = {
    MSYSTEM = 'UCRT64',
    CHERE_INVOKING = '1',
  }
  config.win32_system_backdrop = 'Acrylic'   -- Win10'daysan sil
  config.launch_menu = {
    { label = 'UCRT64',     args = { 'C:/msys64/usr/bin/bash.exe', '-l' } },
    { label = 'PowerShell', args = { 'pwsh.exe', '-NoLogo' } },
    { label = 'cmd',        args = { 'cmd.exe' } },
  }
else
  config.default_prog = { '/bin/bash', '-l' }
  config.launch_menu = {
    { label = 'bash', args = { '/bin/bash', '-l' } },
  }
end

-- ═══ GÖRÜNÜM ═══
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_close_confirmation = 'NeverPrompt'
config.window_background_opacity = 0.92
config.window_padding = { left = 10, right = 10, top = 8, bottom = 4 }
config.adjust_window_size_when_changing_font_size = false
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.65 }
config.tab_max_width = 32

-- ═══ FONT ═══
config.font = wezterm.font_with_fallback {
  { family = 'JetBrains Mono', weight = 'Medium' },
  'Symbols Nerd Font Mono',
  'Segoe UI Emoji',
}
config.font_size = 11.0
config.line_height = 1.1
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

-- ═══ KEYBINDS ═══
config.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1000 }
config.keys = {
  -- Split
  { key = '\\', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-',  mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'x',  mods = 'LEADER', action = act.CloseCurrentPane { confirm = false } },
  { key = 'z',  mods = 'LEADER', action = act.TogglePaneZoomState },

  -- Pane gezinme
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

  -- Launcher
  { key = 'w', mods = 'LEADER', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES|LAUNCH_MENU_ITEMS' } },

  -- Komut paleti
  { key = 'p', mods = 'CTRL|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|COMMANDS|KEY_ASSIGNMENTS' } },

  -- Temizle / ara
  { key = 'k',     mods = 'CTRL|SHIFT', action = act.ClearScrollback 'ScrollbackAndViewport' },
  { key = 'Space', mods = 'CTRL|SHIFT', action = act.QuickSelect },
  { key = 'f',     mods = 'CTRL|SHIFT', action = act.Search { CaseInSensitiveString = '' } },

  -- Font zoom
  { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = act.ResetFontSize },
}

-- Alt+1..9 -> tab  (config.keys'ten SONRA olmak zorunda)
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i), mods = 'ALT', action = act.ActivateTab(i - 1),
  })
end

-- ═══ QUICK SELECT ═══
config.quick_select_patterns = {
  '[0-9a-f]{7,40}',
  '(?:[\\w-]+/)+[\\w.-]+',
  '\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\b',
  '\\b[\\w.+-]+@[\\w-]+\\.[\\w.]+\\b',
  '[a-z_]+::[a-zA-Z_:]+',
}

-- ═══ MOUSE ═══
config.mouse_bindings = {
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'CTRL',
    action = act.OpenLinkAtMouseCursor },
  { event = { Down = { streak = 1, button = 'Right' } }, mods = 'NONE',
    action = act.PasteFrom 'Clipboard' },
}

-- ═══ MAXIMIZE ON START ═══
wezterm.on('gui-startup', function(cmd)
  local _, _, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

require('modules.status').apply_to_config(config)

return config
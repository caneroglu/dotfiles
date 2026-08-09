local wezterm = require 'wezterm'
local act = wezterm.action
local M = {}

local STATE = wezterm.config_dir .. '/.colorscheme'
local DEFAULT = 'Catppuccin Mocha'

local names = {}
for n in pairs(wezterm.color.get_builtin_schemes()) do names[#names + 1] = n end
table.sort(names)

local function index_of(name)
  for i, n in ipairs(names) do if n == name then return i end end
  return 1
end

local function save(name)
  local f = io.open(STATE, 'w')
  if f then f:write(name); f:close() end
end

local function load_saved()
  local f = io.open(STATE, 'r')
  if not f then return nil end
  local n = f:read '*l'; f:close()
  if n and n ~= '' then return n end
end

local function move(window, d)
  wezterm.log_error 'THEME MOVE FIRED'
  local idx = wezterm.GLOBAL.theme_idx
      or index_of(window:effective_config().color_scheme or DEFAULT)
  idx = ((idx + d - 1) % #names) + 1
  wezterm.GLOBAL.theme_idx = idx

  local ov = window:get_config_overrides() or {}
  ov.color_scheme = names[idx]
  window:set_config_overrides(ov)

  window:set_right_status(wezterm.format {
    { Attribute = { Intensity = 'Bold' } },
    { Text = string.format(' %s  [%d/%d] ', names[idx], idx, #names) },
  })
end

wezterm.on('theme-next',   function(w) move(w, 1) end)
wezterm.on('theme-prev',   function(w) move(w, -1) end)
wezterm.on('theme-next10', function(w) move(w, 10) end)
wezterm.on('theme-prev10', function(w) move(w, -10) end)

wezterm.on('theme-open', function(window)
  wezterm.GLOBAL.theme_idx =
      index_of(window:effective_config().color_scheme or DEFAULT)
  move(window, 0)
end)

wezterm.on('theme-commit', function(window)
  local idx = wezterm.GLOBAL.theme_idx
  wezterm.GLOBAL.theme_idx = nil
  window:set_right_status ''
  local ov = window:get_config_overrides() or {}
  ov.color_scheme = nil
  window:set_config_overrides(ov)
  if idx then save(names[idx]) end
  wezterm.reload_configuration()
end)

wezterm.on('theme-cancel', function(window)
  wezterm.GLOBAL.theme_idx = nil
  window:set_right_status ''
  local ov = window:get_config_overrides() or {}
  ov.color_scheme = nil
  window:set_config_overrides(ov)
end)

function M.apply_to_config(config)
  config.color_scheme = load_saved() or DEFAULT

  config.key_tables = config.key_tables or {}
  config.key_tables.theme_picker = {
    { key = 'j',         action = act.EmitEvent 'theme-next' },
    { key = 'DownArrow', action = act.EmitEvent 'theme-next' },
    { key = 'k',         action = act.EmitEvent 'theme-prev' },
    { key = 'UpArrow',   action = act.EmitEvent 'theme-prev' },
    { key = 'PageDown',  action = act.EmitEvent 'theme-next10' },
    { key = 'PageUp',    action = act.EmitEvent 'theme-prev10' },
    { key = 'Enter',  action = act.Multiple { act.EmitEvent 'theme-commit', act.PopKeyTable } },
    { key = 'Escape', action = act.Multiple { act.EmitEvent 'theme-cancel', act.PopKeyTable } },
    { key = 'q',      action = act.Multiple { act.EmitEvent 'theme-cancel', act.PopKeyTable } },
  }

  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = 'F5',
    action = act.Multiple {
      act.EmitEvent 'theme-open',
      act.ActivateKeyTable { name = 'theme_picker', one_shot = false, prevent_fallback = true },
    },
  })
end

return M
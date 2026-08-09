local wezterm = require 'wezterm'
local M = {}

-- ═══ GIT BRANCH (process spawn YOK, dosya okur) ═══
local function git_branch(cwd)
  if not cwd then return nil end
  local dir = cwd
  for _ = 1, 12 do
    local f = io.open(dir .. '/.git/HEAD', 'r')
    if f then
      local line = f:read('*l'); f:close()
      if line then
        return line:match('ref: refs/heads/(.+)') or line:sub(1, 7)
      end
    end
    local parent = dir:match('(.*)[/\\][^/\\]+$')
    if not parent or parent == dir then break end
    dir = parent
  end
end

local function get_cwd(pane)
  local cwd = pane:get_current_working_dir()
  if not cwd then return nil end
  if type(cwd) == 'userdata' then return cwd.file_path end
  return tostring(cwd):gsub('^file://[^/]*', '')
end

-- ═══ PERSISTENT STATE ═══
local STATE = (os.getenv('USERPROFILE') or os.getenv('HOME') or '.')
  :gsub('\\', '/') .. '/.wezterm-focus'

local function load_state()
  local f = io.open(STATE, 'r')
  if not f then return { task = '', start = os.time() } end
  local task = f:read('*l') or ''
  local start = tonumber(f:read('*l')) or os.time()
  f:close()
  return { task = task, start = start }
end

local function save_state(s)
  local f = io.open(STATE, 'w')
  if not f then return end
  f:write(s.task, '\n', tostring(s.start), '\n')
  f:close()
end

-- cache: her saniye disk okumasın
local function state()
  local now = os.time()
  if not wezterm.GLOBAL.st_cache or (wezterm.GLOBAL.st_at or 0) < now - 2 then
    wezterm.GLOBAL.st_cache = load_state()
    wezterm.GLOBAL.st_at = now
  end
  return wezterm.GLOBAL.st_cache
end

local function set_state(s)
  wezterm.GLOBAL.st_cache = s
  wezterm.GLOBAL.st_at = os.time()
  save_state(s)
end

local function fmt_dur(s)
  if s < 3600 then return string.format('%dm', s // 60) end
  return string.format('%dh%02dm', s // 3600, (s % 3600) // 60)
end

-- ═══ RENKLER ═══
local C = {
  dim    = '#5c6370',
  fg     = '#abb2bf',
  accent = '#61afef',
  warn   = '#e5c07b',
  alert  = '#e06c75',
  ok     = '#98c379',
  focus  = '#c678dd',
}

local function seg(color, text)
  return { { Foreground = { Color = color } }, { Text = text } }
end

local function render(parts)
  local out = {}
  for _, p in ipairs(parts) do
    for _, item in ipairs(p) do table.insert(out, item) end
  end
  table.insert(out, { Text = ' ' })
  return wezterm.format(out)
end

-- ═══ SOL: INTENTION ANCHOR ═══
wezterm.on('update-status', function(window, pane)
  local parts = {}

  if window:leader_is_active() then
    table.insert(parts, seg(C.alert, '  LEADER  '))
  end

  local st = state()
  if st.task ~= '' then
    table.insert(parts, seg(C.focus, '  ◆ ' .. st.task .. ' '))
  else
    table.insert(parts, seg(C.dim, '  ◇ (hedef yok) '))
  end

  window:set_left_status(render(parts))

  -- ═══ SAĞ ═══
  local right = {}

  -- git
  local branch = git_branch(get_cwd(pane))
  if branch then
    table.insert(right, seg(C.ok, ' ' .. branch .. ' '))
    table.insert(right, seg(C.dim, '│'))
  end

  -- session süresi
  local el = os.time() - st.start
  local tcol = el > 10800 and C.alert or (el > 7200 and C.warn or C.dim)
  table.insert(right, seg(tcol, ' ⏱ ' .. fmt_dur(el) .. ' '))

  -- batarya (varsa)
  for _, b in ipairs(wezterm.battery_info()) do
    local pct = math.floor(b.state_of_charge * 100)
    local bcol = pct < 20 and C.alert or (pct < 40 and C.warn or C.dim)
    local icon = b.state == 'Charging' and '⚡' or '▮'
    table.insert(right, seg(bcol, string.format(' %s%d%% ', icon, pct)))
    table.insert(right, seg(C.dim, '│'))
    break
  end

  -- saat + gece uyarısı
  local h = tonumber(os.date('%H'))
  local m = tonumber(os.date('%M'))
  local late = (h >= 23 and (h > 23 or m >= 30)) or h < 5
  if late then
    table.insert(right, seg(C.alert, ' 🌙 ' .. os.date('%H:%M') .. ' — YAT AMK '))
  else
    table.insert(right, seg(C.fg, ' ' .. os.date('%H:%M') .. ' '))
  end

  window:set_right_status(render(right))
end)

-- ═══ KEYBINDS ═══
function M.keys()
  return {
    -- LEADER+i -> hedef belirle (timer da sıfırlanır)
    { key = 'i', mods = 'LEADER', action = wezterm.action.PromptInputLine {
      description = wezterm.format {
        { Foreground = { Color = C.focus } },
        { Text = 'Şu an ne yapıyorsun? (boş = temizle)' },
      },
      action = wezterm.action_callback(function(_, _, line)
        if line == nil then return end
        set_state { task = line, start = os.time() }
      end),
    }},

    -- LEADER+I -> sadece timer sıfırla, hedef kalsın
    { key = 'I', mods = 'LEADER', action = wezterm.action_callback(function()
      local s = state()
      set_state { task = s.task, start = os.time() }
    end)},
  }
end

function M.apply_to_config(config)
  config.status_update_interval = 1000
  for _, k in ipairs(M.keys()) do table.insert(config.keys, k) end
end

return M
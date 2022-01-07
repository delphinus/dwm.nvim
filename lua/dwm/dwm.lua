local M = {}

--- Open a new window
-- The master pane move to the top of stacks, and a new window appears.
-- before:          after:
--   ┌────┬────┬────┐    ┌────┬────┬─────┐
--   │    │    │ S1 │    │    │    │ S1  │
--   │    │    │    │    │    │    ├─────┤
--   │    │    ├────┤    │    │    │ S2  │
--   │ M1 │ M2 │ S2 │    │ M1 │ M2 ├─────┤
--   │    │    │    │    │    │    │ S3  │
--   │    │    ├────┤    │    │    ├─────┤
--   │    │    │ S3 │    │    │    │ S4  │
--   └────┴────┴────┘    └────┴────┴─────┘
function M:new()
  self:stack()
  vim.cmd [[topleft new]]
  self:reset()
end

--- Move the current master pane to the stack
-- The layout should be the followings.
--
--   ┌────────┐
--   │   M1   │
--   ├────────┤
--   │   M2   │
--   ├────────┤
--   │   S1   │
--   ├────────┤
--   │   S2   │
--   ├────────┤
--   │   S3   │
--   └────────┘
function M:stack()
  local wins = self:get_wins()
  if #wins == 1 then
    return
  end
  for i = math.min(self.master_pane_count, #wins), 1, -1 do
    vim.api.nvim_set_current_win(wins[i])
    self:wincmd "K"
  end
end

--- Move the current window to the master pane.
-- The previous master window is added to the top of the stack. If the current
-- window is in the master pane already, it is moved to the top of the stack.
function M:focus()
  local wins = self:get_wins()
  if #wins == 1 then
    return
  end
  local current = vim.api.nvim_get_current_win()
  if wins[1] == current then
    self:wincmd "w"
    current = vim.api.nvim_get_current_win()
  end
  self:stack()
  if current ~= vim.api.nvim_get_current_win() then
    vim.api.nvim_set_current_win(current)
  end
  self:wincmd "H"
  self:reset()
end

--- Handler for BufWinEnter autocmd
-- Recreate layout broken by the new window
function M:buf_win_enter()
  if
    #self:get_wins() == 1
    or vim.w.dwm_disabled
    or vim.b.dwm_disabled
    or not vim.opt.buflisted:get()
    or vim.opt.filetype:get() == ""
    or vim.opt.filetype:get() == "help"
    or vim.opt.buftype:get() == "quickfix"
  then
    return
  end

  self:wincmd "K" -- Move the new window to the top of the stack
  self:focus() -- Focus the new window (twice :)
  self:focus()
end

--- Close the current window
function M:close()
  vim.api.nvim_win_close(0, false)
  if self:get_wins()[1] == vim.api.nvim_get_current_win() then
    self:wincmd "H"
    self:stack()
    self:reset()
  end
end

--- Resize the master pane
function M:resize(diff)
  local wins = self:get_wins()
  local current = vim.api.nvim_get_current_win()
  local size = vim.api.nvim_win_get_width(current)
  local direction = wins[1] == current and 1 or -1
  local width = size + diff * direction
  vim.api.nvim_win_set_width(current, width)
  self.master_pane_width = width
end

--- Rotate windows
-- @param left Bool value to rotate left. Default: false
function M:rotate(left)
  self:stack()
  local wins = self:get_wins()
  if left then
    vim.api.nvim_set_current_win(wins[1])
    self:wincmd "J"
  else
    vim.api.nvim_set_current_win(wins[#wins])
    self:wincmd "K"
  end
  self:reset()
end

--- Reset height and width of the windows
-- This should be run after calling stack().
function M:reset()
  local wins = self:get_wins()
  if #wins == 1 then
    return
  end

  local width = self:calculate_width()
  if width * self.master_pane_count > vim.o.columns then
    self:warn "invalid width. use defaults"
    width = self:default_master_pane_width()
  end

  if #wins <= self.master_pane_count then
    for i = self.master_pane_count, 1, -1 do
      vim.api.nvim_set_current_win(wins[i])
      self:wincmd "H"
      if i ~= 1 then
        vim.api.nvim_win_set_width(wins[i], width)
      end
      vim.api.nvim_win_set_option(wins[i], "winfixwidth", true)
    end
    return
  end

  for i = self.master_pane_count, 1, -1 do
    vim.api.nvim_set_current_win(wins[i])
    self:wincmd "H"
  end
  for _, w in ipairs(wins) do
    vim.api.nvim_win_set_option(w, "winfixwidth", false)
  end
  for i = 1, self.master_pane_count do
    vim.api.nvim_win_set_width(wins[i], width)
    vim.api.nvim_win_set_option(wins[i], "winfixwidth", true)
  end
end

function M:parse_percentage(v) -- luacheck: ignore 212
  return tonumber(v:match "^(%d+)%%$")
end

function M:calculate_width()
  if type(self.master_pane_width) == "number" then
    return self.master_pane_width
  elseif type(self.master_pane_width) == "string" then
    local percentage = self:parse_percentage(self.master_pane_width)
    return math.floor(vim.o.columns * percentage / 100)
  end
  return self:default_master_pane_width()
end

function M:default_master_pane_width()
  return math.floor(vim.o.columns / (self.master_pane_count + 1))
end

function M:get_wins() -- luacheck: ignore 212
  local wins = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local is_float = vim.api.nvim_win_get_config(w).relative ~= ""
    if not is_float then
      table.insert(wins, w)
    end
  end
  return wins
end

function M:wincmd(cmd)
  vim.cmd("wincmd " .. cmd)
end -- luacheck: ignore 212

function M:map(lhs, f)
  if vim.keymap then
    vim.keymap.set("n", lhs, f, { silent = true })
    return
  end
  local rhs
  if type(f) == "function" then
    if not _G[self.func_var_name] then
      _G[self.func_var_name] = self.funcs
    end
    self.funcs[#self.funcs + 1] = f
    rhs = ([[<Cmd>lua %s[%d]()<CR>]]):format(self.func_var_name, #self.funcs)
  else
    rhs = f
  end
  vim.api.nvim_set_keymap("n", lhs, rhs, { noremap = true, silent = true })
end

function M:warn(msg) -- luacheck: ignore 212
  vim.api.nvim_echo({ { msg, "WarningMsg" } }, true, {})
end

return (function()
  local self = {
    func_var_name = ("__dwm_funcs_%d__"):format(vim.loop.now()),
    funcs = {},
    master_pane_count = 1,
  }
  return setmetatable(self, { __index = M })
end)()

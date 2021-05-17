local M = {}

--- Open a new window
-- The master pane move to the top of stacks, and a new window appears.
-- before:          after:
--   ┌─────┬─────┐    ┌─────┬─────┐
--   │     │ S1  │    │     │ S1  │
--   │     │     │    │     ├─────┤
--   │     ├─────┤    │     │ S2  │
--   │  M  │ S2  │    │  M  ├─────┤
--   │     │     │    │     │ S3  │
--   │     ├─────┤    │     ├─────┤
--   │     │ S3  │    │     │ S4  │
--   └─────┴─────┘    └─────┴─────┘
function M:new()
  self:stack()
  vim.cmd[[vertical topleft new]]
  self:reset()
end

--- Move the current master pane to the stack
-- The layout should be the followings.
--
-- direction: true  direction: false
--   ┌────────┐       ┌────────┐
--   │   M    │       │   S1   │
--   ├────────┤       ├────────┤
--   │   S1   │       │   S2   │
--   ├────────┤       ├────────┤
--   │   S2   │       │   S3   │
--   ├────────┤       ├────────┤
--   │   S3   │       │   M    │
--   └────────┘       └────────┘
-- @param bottom Bool value to stack the master. Default: false
function M:stack(bottom) -- luacheck: ignore 212
  local master_pane_id = vim.api.nvim_list_wins()[1]
  vim.cmd(('%dwincmd %s'):format(
    vim.api.nvim_win_get_number(master_pane_id),
    bottom and 'J' or 'K'
  ))
end

--- Move the current window to the master pane.
-- The previous master window is added to the top of the stack. If the current
-- window is in the master pane already, it is moved to the top of the stack.
function M:focus()
  local wins = vim.api.nvim_list_wins()
  if #wins == 1 then
    return
  end
  local current = vim.api.nvim_get_current_win()
  if wins[1] == current then
    vim.cmd[[wincmd w]]
  end
  self:stack()
  vim.api.nvim_exec(([[
    %dwincmd w
    wincmd H
  ]]):format(current), false, {})
  self:reset()
end

--- Handler for BufWinEnter autocmd
-- Recreate layout broken by the new window
function M:buf_win_enter()
  if #vim.api.nvim_list_wins() == 1 or vim.b.dwm_disabled or
    not vim.bo.buflisted or vim.bo.filetype == '' or vim.bo.filetype == 'help'
    or vim.bo.buftype == 'quickfix' then
    return
  end

  vim.cmd[[wincmd K]] -- Move the new window to the top of the stack
  self:focus() -- Focus the new window (twice :)
  self:focus()
end

--- Close the current window
function M:close()
  vim.api.nvim_win_close(0, false)
  local wins = vim.api.nvim_list_wins()
  if wins[1] == vim.api.nvim_get_current_win() then
    vim.cmd[[wincmd H]]
    self:reset()
  end
end

--- Resize the master pane
function M:resize(diff)
  local wins = vim.api.nvim_list_wins()
  local current = vim.api.nvim_get_current_win()
  local size = vim.api.nvim_win_get_width(current)
  local direction = wins[1] == current and 1 or -1
  vim.api.nvim_win_set_width(current, size + diff * direction)
  if self.master_pane_width then
    self.master_pane_width = self.master_pane_width + diff
  end
end

--- Rotate windows
-- @param left Bool value to rotate left. Default: false
function M:rotate(left)
  self:stack(not left)
  vim.cmd(('wincmd %s'):format(left and 'W' or 'w'))
  vim.cmd[[wincmd H]]
  self:reset()
end

function M:reset()
  local width
  if self.master_pane_width then
    if type(self.master_pane_width) == 'number' then
      width = self.master_pane_width
    else
      local percentage = tonumber(self.master_pane_width:match'^(%d+)%%$')
      width = math.floor(vim.o.columns * percentage / 100)
    end
  else
    width = math.floor(vim.o.columns / 2)
  end

  local wins = vim.api.nvim_list_wins()
  local height = math.floor(vim.o.lines / (#wins - 1))
  for i, w in ipairs(wins) do
    if i == 1 then
      vim.api.nvim_win_set_width(w, width)
    else
      vim.api.nvim_win_set_height(w, height)
    end
  end
end

function M:map(lhs, f)
  local rhs
  if type(f) == 'function' then
    if not _G[self.func_var_name] then
      _G[self.func_var_name] = self.funcs
    end
    self.funcs[#self.funcs + 1] = f
    rhs = ([[<Cmd>lua %s[%d]()<CR>]]):format(self.func_var_name, #self.funcs)
  else
    rhs = f
  end
  vim.api.nvim_set_keymap('n', lhs, rhs, {noremap = true, silent = true})
end

return (function()
  local self = {
    func_var_name = ('__dwm_funcs_%d__'):format(vim.loop.now()),
    funcs = {},
  }
  return setmetatable(self, {__index = M})
end)()

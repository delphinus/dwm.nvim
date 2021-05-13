local master_pane_width

local M = {}

M.setup = function(opts)
  vim.validate{
    opts = {opts, 'table'},
  }
  vim.validate{
    master_pane_width = {
      opts.master_pane_width,
      function(v)
        return type(v) == 'numbfer' or type(v) == 'string' and v:match'^%d+%%$'
      end,
      'number (50) or numeber+% (66%)',
    },
  }
  master_pane_width = opts.master_pane_width
end

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
M.new = function()
  M.stack()
  vim.cmd[[vertical topleft new]]
  M.resize_master_pane_width()
end

--- Move the current master pane to the stack
-- The layout should be the followings.
--
-- is_clockwise: true  is_clockwise: false
--   ┌────────┐          ┌────────┐
--   │   M    │          │   S1   │
--   ├────────┤          ├────────┤
--   │   S1   │          │   S2   │
--   ├────────┤          ├────────┤
--   │   S2   │          │   S3   │
--   ├────────┤          ├────────┤
--   │   S3   │          │   M    │
--   └────────┘          └────────┘
-- @param is_clockwise Bool value for the direction. Default: true
M.stack = function(is_clockwise)
  is_clockwise = is_clockwise or true
  local master_pane_id = vim.api.nvim_list_wins()[1]
  vim.cmd(('%dwincmd %s'):format(
    vim.api.nvim_win_get_number(master_pane_id),
    is_clockwise and 'K' or 'J'
  ))
end

--- Move the current window to the master pane.
-- The previous master window is added to the top of the stack. If the current
-- window is in the master pane already, it is moved to the top of the stack.
M.focus = function()
  local wins = vim.api.nvim_list_wins()
  if #wins == 1 then
    return
  end
  local current = vim.api.nvim_get_current_win()
  if wins[1] == current then
    vim.cmd[[wincmd w]]
  end
  M.stack()
  vim.api.nvim_exec(([[
    %dwincmd w
    wincmd H
  ]]):format(current), false, {})
  M.resize_master_pane_width()
end

--- Handler for BufWinEnter autocmd
-- Recreate layout broken by the new window
M.buf_win_enter = function()
  if #vim.api.nvim_list_wins() == 1 or vim.b.dwm_disabled or
    not vim.bo.buflisted or vim.bo.filetype == '' or vim.bo.filetype == 'help'
    or vim.bo.buftype == 'quickfix' then
    return
  end

  vim.cmd[[wincmd K]] -- Move the new window to the top of the stack
  M.focus() -- Focus the new window (twice :)
  M.focus()
end

--- Close the current window
M.close = function()
  local in_master = vim.fn.winnr() == 1
  vim.cmd[[close]]
  if in_master then
    vim.cmd[[wincmd H]]
    M.resize_master_pane_width()
  end
end

--- Widen the master pane 
function M.widen_master()
end

M.resize_master_pane_width = function()
  local width
  if master_pane_width then
    if type(master_pane_width) == 'number' then
      width = master_pane_width
    else
      local percentage = tonumber(master_pane_width:match'^(%d+)%%$')
      width = vim.o.columns * percentage / 100
    end
  else
    width = vim.o.columns / 2
  end

  local wins = vim.api.nvim_list_wins()
  local height = vim.o.rows / (#wins - 1)
  for i, w in ipairs(wins) do
    if i == 1 then
      vim.api.nvim_win_set_width(w, width)
    else
      vim.api.nvim_win_set_height(w, height)
    end
  end
end

return M

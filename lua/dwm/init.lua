_G.__dwm__funcs__ = {}
local master_pane_width

local M = {}

-- Setup dwm.nvim
M.setup = function(opts)
  vim.validate{
    opts = {opts, 'table'},
  }
  opts = vim.tbl_extend('force', {
    autocmd = true,
    key_maps = true,
    plug_maps = false,
  }, opts)
  vim.validate{
    master_pane_width = {
      opts.master_pane_width,
      function(v)
        if not v or type(v) == 'number' then
          return true
        end
        return type(v) == 'string' and v:match'^%d+%%$'
      end,
      'number (50) or numeber+% (66%)',
    },
  }
  master_pane_width = opts.master_pane_width

  -- for backwards compatibility
  if opts.plug_maps then
    M.map('<Plug>DWMRotateCounterclockwise', function() M.rotate(false) end)
    M.map('<Plug>DWMRotateClockwise', function() M.rotate(true) end)
    M.map('<Plug>DWMNew', M.new)
    M.map('<Plug>DWMClose', M.close)
    M.map('<Plug>DWMFocus', M.focus)
    M.map('<Plug>DWMGrowMaster', function() M.resize_master(1) end)
    M.map('<Plug>DWMShrinkMaster', function() M.resize_master(-1) end)
  end

  if opts.key_maps then
    M.map('<C-,>', function() M.rotate(false) end)
    M.map('<C-.>', function() M.rotate(true) end)
    M.map('<C-n>', M.new)
    M.map('<C-c>', M.close)
    M.map('<C-@>', M.focus)
    M.map('<C-Space>', M.focus)
    M.map('<C-l>', function() M.resize_master(1) end)
    M.map('<C-h>', function() M.resize_master(-1) end)
  end

  if opts.autocmd then
    vim.api.nvim_exec([[
      augroup dwm.nvim
        autocmd!
        autocmd BufWinEnter * lua require'dwm'.buf_win_enter()
      augroup end
    ]], false)
  end
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
  M.reset_master()
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
-- @param direction Bool value for the direction. Default: true (mean clockwise)
M.stack = function(direction)
  direction = direction or true
  local master_pane_id = vim.api.nvim_list_wins()[1]
  vim.cmd(('%dwincmd %s'):format(
    vim.api.nvim_win_get_number(master_pane_id),
    direction and 'K' or 'J'
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
  M.reset_master()
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
  vim.api.nvim_win_close(0, false)
  local wins = vim.api.nvim_list_wins()
  if wins[1] == vim.api.nvim_get_current_win() then
    vim.cmd[[wincmd H]]
    M.reset_master()
  end
end

--- Resize the master pane 
function M.resize_master(diff)
  local wins = vim.api.nvim_list_wins()
  local current = vim.api.nvim_get_current_win()
  local size = vim.api.nvim_win_get_width(current)
  local direction = wins[1] == current and 1 or -1
  vim.api.nvim_win_set_width(current, size + diff * direction)
  if master_pane_width then
    master_pane_width = master_pane_width + diff
  end
end

-- Rotate windows
function M.rotate(direction)
  direction = direction or true
  M.stack(direction)
  vim.cmd(('wincmd %s'):format(direction and 'W' or 'w'))
  vim.cmd[[wincmd H]]
  M.resize_master()
end

function M.map(lhs, rhs, opts)
  opts = vim.tbl_extend('force', {
    noremap = true,
    silent = true,
  }, opts or {})
  if type(rhs) == 'function' then
    local next = #_G.__dwm__funcs__ + 1
    _G.__dwm__funcs__[next] = rhs
    rhs = (':lua _G.__dwm__funcs__[%d]()'):format(next)
  end
  vim.api.nvim_set_keymap('n', lhs, rhs, opts)
end

M.reset_master = function()
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

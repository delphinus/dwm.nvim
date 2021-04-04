local M = {}

--- Move the current master pane to the stack
-- The layout should be the followings.
--
--   is_clockwise: true  is_clockwise: false
--   ┌────────┐          ┌────────┐
--   │   M    │          │   S1   │
--   ├────────┤          ├────────┤
--   │   S1   │          │   S2   │
--   ├────────┤          ├────────┤
--   │   S2   │          │   S3   │
--   ├────────┤          ├────────┤
--   │   S3   │          │   M    │
--   └────────┘          └────────┘
-- @param is_clockwise Bool value for the direction.
M.stack = function(is_clockwise)
  vim.api.nvim_set_current_win(M.master_pane_id())
  local cmd = is_clockwise and 'K' or 'J'
  vim.cmd('wincmd '..cmd)
end

M.reset_width = function()
  vim.cmd[[wincmd =]]
end

M.master_pane_id = function()
  return vim.api.nvim_list_wins()[1]
end

return M

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
  vim.cmd(('%dwincmd %s'):format(
    vim.api.nvim_win_get_number(M.master_pane_id()),
    is_clockwise and 'K' or 'J'
  ))
end

M.master_pane_id = function()
  return vim.api.nvim_list_wins()[1]
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

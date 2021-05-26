local dwm = require'dwm.dwm'

local M

M = {
  buf_win_enter = function() dwm:buf_win_enter() end,
  close = function() dwm:close() end,
  focus = function() dwm:focus() end,
  grow = function() dwm:resize(1) end,
  map = function(lhs, rhs) dwm:map(lhs, rhs) end,
  new = function() dwm:new() end,
  resize = function(diff) dwm:resize(diff) end,
  rotate = function() dwm:rotate() end,
  rotateLeft = function() dwm:rotate(true) end,
  shrink = function() dwm:resize(-1) end,
  dwm = dwm,

  setup = function(opts)
    opts = vim.tbl_extend('force', {
      autocmd = true,
      key_maps = true,
      plug_maps = false,
      master_pane_count = 1,
    }, opts or {})
    vim.validate{
      master_pane_count = {
        opts.master_pane_count,
        function(v) return type(v) == 'number' and v > 0 end,
        'number greater than 0',
      },
      master_pane_width = {
        opts.master_pane_width,
        function(v)
          if not v or type(v) == 'number' and v > 0 then return true end
          if not type(v) == 'string' then return false end
          local percentage = dwm:parse_percentage(v)
          return percentage > 0 and percentage < 100
        end,
        'number (50) or number+% (66%)',
      },
    }
    dwm.master_pane_count = opts.master_pane_count
    dwm.master_pane_width = opts.master_pane_width

    -- for backwards compatibility
    if opts.plug_maps then
      M.map('<Plug>DWMRotateCounterclockwise', M.rotateLeft)
      M.map('<Plug>DWMRotateClockwise', M.rotate)
      M.map('<Plug>DWMNew', M.new)
      M.map('<Plug>DWMClose', M.close)
      M.map('<Plug>DWMFocus', M.focus)
      M.map('<Plug>DWMGrowMaster', M.grow)
      M.map('<Plug>DWMShrinkMaster', M.shrink)
    end

    if opts.key_maps then
      M.map('<C-j>', '<C-w>w')
      M.map('<C-k>', '<C-w>W')
      M.map('<C-,>', M.rotateLeft)
      M.map('<C-.>', M.rotate)
      M.map('<C-n>', M.new)
      M.map('<C-c>', M.close)
      M.map('<C-@>', M.focus)
      M.map('<C-Space>', M.focus)
      M.map('<C-l>', M.grow)
      M.map('<C-h>', M.shrink)
    end

    if opts.autocmd then
      vim.api.nvim_exec([[
        augroup dwm.nvim
          autocmd!
          autocmd BufWinEnter * lua require'dwm'.buf_win_enter()
        augroup end
      ]], false)
    end

    if vim.v.vim_did_enter == 1 then
      dwm:reset()
    else
      vim.cmd[[autocmd VimEnter * ++once lua require'dwm'.dwm:reset()]]
    end
  end,
}

return M

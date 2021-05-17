local dwm = require'dwm.dwm'

local M

M = {
  buf_win_enter = function() dwm:buf_win_enter() end,
  close = function() dwm:close() end,
  focus = function() dwm:focus() end,
  map = function(lhs, f) dwm:map(lhs, f) end,
  new = function() dwm:new() end,
  resize = function(diff) dwm:resize(diff) end,
  rotate = function(direction) dwm:rotate(direction) end,

  setup = function(opts)
    opts = vim.tbl_extend('force', {
      autocmd = true,
      key_maps = true,
      plug_maps = false,
    }, opts or {})
    vim.validate{
      master_pane_width = {
        opts.master_pane_width,
        function(v)
          if not v or type(v) == 'number' and v > 0 then
            return true
          end
          return type(v) == 'string' and v:match'^d+%%$'
        end,
        'number (50) or number+% (66%)',
      },
    }

    if opts.master_pane_width then
      dwm.master_pane_width = opts.master_pane_width
    end

    -- for backwards compatibility
    if opts.plug_maps then
      M.map('<Plug>DWMRotateCounterclockwise', function() M.rotate(false) end)
      M.map('<Plug>DWMRotateClockwise', function() M.rotate(true) end)
      M.map('<Plug>DWMNew', M.new)
      M.map('<Plug>DWMClose', M.close)
      M.map('<Plug>DWMFocus', M.focus)
      M.map('<Plug>DWMGrowMaster', function() M.resize(1) end)
      M.map('<Plug>DWMShrinkMaster', function() M.resize(-1) end)
    end

    if opts.key_maps then
      M.map('<C-j>', '<C-w>w')
      M.map('<C-k>', '<C-w>W')
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
  end,
}

return M

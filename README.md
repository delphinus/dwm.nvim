# dwm.nvim

Yet another implementation for [dwm.vim][].

[dwm.vim]: https://github.com/spolu/dwm.vim

## What's this?

A port for Neovim to implement [dwm.vim][]'s features and more.

***This plugin is experimental.***

## Usage

```lua
-- for packer.nvim
{
  'delphinus/dwm.nvim',
  config = function()
    local dwm = require'dwm'
    dwm.setup{
      key_maps = false,
      master_pane_count = 1,
      master_pane_width = '60%',
    }
    vim.keymap.set('n', '<C-j>', '<C-w>w')
    vim.keymap.set('n', '<C-k>', '<C-w>W')
    vim.keymap.set('n', '<A-CR>', dwm.focus)
    vim.keymap.set('n', '<C-@>', dwm.focus)
    vim.keymap.set('n', '<C-Space>', dwm.focus)
    vim.keymap.set('n', '<C-l>', dwm.grow)
    vim.keymap.set('n', '<C-h>', dwm.shrink)
    vim.keymap.set('n', '<C-n>', dwm.new)
    vim.keymap.set('n', '<C-q>', dwm.rotateLeft)
    vim.keymap.set('n', '<C-s>', dwm.rotate)
    vim.keymap.set('n', '<C-c>', function()
      vim.notify('closing!', vim.log.levels.INFO)
      dwm.close()
    end)

    -- For users that do not have vim.keymap
    -- dwm.map('<C-j>', '<C-w>w')
    -- dwm.map('<C-k>', '<C-w>W')
    -- dwm.map('<A-CR>', dwm.focus)
    -- dwm.map('<C-@>', dwm.focus)
    -- dwm.map('<C-Space>', dwm.focus)
    -- dwm.map('<C-l>', dwm.grow)
    -- dwm.map('<C-h>', dwm.shrink)
    -- dwm.map('<C-n>', dwm.new)
    -- dwm.map('<C-q>', dwm.rotateLeft)
    -- dwm.map('<C-s>', dwm.rotate)
    -- dwm.map('<C-c>', function()
    --   -- You can use any Lua function to map.
    --   vim.notify('closing!', vim.log.levels.INFO)
    --   dwm.close()
    -- end)

    -- When b:dwm_disabled is set, all features are disabled.
    vim.cmd[[au BufRead * if &previewwindow | let b:dwm_disabled = 1 | endif]]
  end,
},
```

---@class dwm.main.Options
---@field autocmd boolean
---@field key_maps boolean
---@field plug_maps boolean
---@field master_pane_count integer
---@field master_pane_width integer|string

---@class dwm.main.Dwm
---@field default_options dwm.main.Options
---@field options dwm.main.Options
local Dwm = {}

---@return dwm.main.Dwm
Dwm.new = function()
  return setmetatable({
    default_options = {
      autocmd = true,
      key_maps = true,
      plug_maps = false,
      master_pane_count = 1,
    },
  }, { __index = Dwm })
end

---@param opts dwm.main.Options?
function Dwm:setup(opts)
  self.options = vim.tbl_extend("force", self.default_options, opts or {})
  vim.validate {
    autocmd = { self.options.autocmd, "boolean" },
    key_maps = { self.options.key_maps, "boolean" },
    plug_maps = { self.options.plug_maps, "boolean" },
    master_pane_count = {
      self.options.master_pane_count,
      ---@param v any
      ---@return boolean
      function(v)
        return type(v) == "number" and v > 0
      end,
      "number greater than 0",
    },
    master_pane_width = {
      self.options.master_pane_width,
      ---@param v any
      ---@return boolean
      function(v)
        if type(v) == "number" then
          return v > 0
        end
        return self:parse_percentage(v) and v > 0 and v < 100 or false
      end,
      "number (66) or number+% string ('66%')",
    },
  }
end

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
function Dwm:new_win()
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
function Dwm:stack()
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
function Dwm:focus()
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
function Dwm:buf_win_enter()
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
function Dwm:close()
  vim.api.nvim_win_close(0, false)
  if self:get_wins()[1] == vim.api.nvim_get_current_win() then
    self:wincmd "H"
    self:stack()
    self:reset()
  end
end

--- Resize the master pane
function Dwm:resize(diff)
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
function Dwm:rotate(left)
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
function Dwm:reset()
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

---@param v any
---@return number?
function Dwm:parse_percentage(v) -- luacheck: ignore 212
  return type(v) == "string" and tonumber(v:match "^(%d+)%%$") or nil
end

function Dwm:calculate_width()
  if type(self.master_pane_width) == "number" then
    return self.master_pane_width
  elseif type(self.master_pane_width) == "string" then
    local percentage = self:parse_percentage(self.master_pane_width)
    return math.floor(vim.o.columns * percentage / 100)
  end
  return self:default_master_pane_width()
end

function Dwm:default_master_pane_width()
  return math.floor(vim.o.columns / (self.master_pane_count + 1))
end

function Dwm:get_wins() -- luacheck: ignore 212
  local wins = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local is_float = vim.api.nvim_win_get_config(w).relative ~= ""
    if not is_float then
      table.insert(wins, w)
    end
  end
  return wins
end

function Dwm:wincmd(cmd)
  vim.cmd("wincmd " .. cmd)
end -- luacheck: ignore 212

function Dwm:warn(msg) -- luacheck: ignore 212
  vim.api.nvim_echo({ { msg, "WarningMsg" } }, true, {})
end

return (function()
  local self = {
    funcs = {},
    master_pane_count = 1,
  }
  return setmetatable(self, { __index = Dwm })
end)()

local M = {}

-- Store Utilities we'll use frequently
local telescopeUtilities = require('telescope.utils')
local plenaryStrings = require('plenary.strings')
local devIcons = require('nvim-web-devicons')

-- Obtain Filename icon width
M.fileTypeIconWidth = plenaryStrings.strdisplaywidth(devIcons.get_icon('fname', { default = true }))

-- Function to get buffer number by full file path
function M.get_buffer_number_by_path(filepath)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == filepath then return bufnr end
  end
  return nil
end

-- Helper function to get path and tail
function M.getPathAndTail(fileName)
  -- Get the Tail
  local bufferNameTail = telescopeUtilities.path_tail(fileName)

  -- Now remove the tail from the Full Path
  local pathWithoutTail = require('plenary.strings').truncate(fileName, #fileName - #bufferNameTail, '')

  -- Apply truncation and other pertaining modifications to the path according to Telescope path rules
  local pathToDisplay = telescopeUtilities.transform_path({
    path_display = { 'truncate' },
  }, pathWithoutTail)

  -- Return as Tuple
  return bufferNameTail, pathToDisplay
end

-- Function to safely require a module
function M.safe_require(module)
  local ok, result = pcall(require, module)
  return ok and result or nil
end

-- Function to check if all dependencies are available
function M.has_dependencies()
  local deps = {
    plenary = M.safe_require('plenary'),
    devicons = M.safe_require('nvim-web-devicons'),
    grapple = M.safe_require('grapple'),
  }

  for name, module in pairs(deps) do
    if not module then
      vim.notify('telescope-pretty-pickers requires ' .. name, vim.log.levels.WARN)
      return false
    end
  end

  return true
end

return M
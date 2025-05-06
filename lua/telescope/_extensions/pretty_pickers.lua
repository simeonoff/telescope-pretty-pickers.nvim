local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
  vim.notify(
    'Telescope Pretty Pickers requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)',
    vim.log.levels.WARN
  )
  return false
end

-- Check if dependencies are available
local function safe_require(module)
  local ok, result = pcall(require, module)
  return ok and result or nil
end

local function has_dependencies()
  local deps = {
    plenary = safe_require('plenary'),
    devicons = safe_require('nvim-web-devicons'),
    grapple = safe_require('grapple'),
  }

  for name, module in pairs(deps) do
    if not module then
      vim.notify('telescope-pretty-pickers requires ' .. name, vim.log.levels.WARN)
      return false
    end
  end

  return true
end

-- Core module implementation
local pretty_pickers = {}

if has_dependencies() then
  -- Import individual pickers directly
  pretty_pickers.files = require('telescope._extensions.pretty_pickers.pickers.files')
  pretty_pickers.grep = require('telescope._extensions.pretty_pickers.pickers.grep')

  -- Import LSP pickers
  local lsp_pickers = require('telescope._extensions.pretty_pickers.pickers.lsp')
  pretty_pickers.document_symbols = lsp_pickers.document_symbols
  pretty_pickers.workspace_symbols = lsp_pickers.workspace_symbols
  pretty_pickers.lsp_references = lsp_pickers.lsp_references

  -- Import other pickers
  pretty_pickers.buffers = require('telescope._extensions.pretty_pickers.pickers.buffers')
  pretty_pickers.grapple = require('telescope._extensions.pretty_pickers.pickers.grapple')
end

-- Register the extension with telescope
return telescope.register_extension({
  exports = pretty_pickers,
})


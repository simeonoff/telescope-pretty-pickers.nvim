local utils = require('telescope._extensions.pretty_pickers.utils')
local telescopeUtilities = require('telescope.utils')
local telescopeMakeEntryModule = require('telescope.make_entry')
local telescopeEntryDisplayModule = require('telescope.pickers.entry_display')
local kind_icons = require('kind')

local M = {}

function M.document_symbols(opts)
  if opts ~= nil and type(opts) ~= 'table' then
    print('Options must be a table.')
    return
  end

  local options = opts or {}

  local originalEntryMaker = telescopeMakeEntryModule.gen_from_lsp_symbols(options)

  options.entry_maker = function(line)
    local originalEntryTable = originalEntryMaker(line)

    local displayer = telescopeEntryDisplayModule.create({
      separator = ' ',
      items = {
        { width = utils.fileTypeIconWidth },
        { width = 20 },
        { remaining = true },
      },
    })

    originalEntryTable.display = function(entry)
      return displayer({
        string.format('%s', kind_icons.icons[(entry.symbol_type:lower():gsub('^%l', string.upper))]),
        { entry.symbol_type:lower(), 'TelescopeResultsVariable' },
        { entry.symbol_name, 'TelescopeResultsConstant' },
      })
    end

    return originalEntryTable
  end

  require('telescope.builtin').lsp_document_symbols(options)
end

function M.workspace_symbols(opts)
  if opts ~= nil and type(opts) ~= 'table' then
    print('Options must be a table.')
    return
  end

  local options = opts or {}

  local originalEntryMaker = telescopeMakeEntryModule.gen_from_lsp_symbols(options)

  options.entry_maker = function(line)
    local originalEntryTable = originalEntryMaker(line)

    local displayer = telescopeEntryDisplayModule.create({
      separator = ' ',
      items = {
        { width = utils.fileTypeIconWidth },
        { width = 15 },
        { width = 30 },
        { width = nil },
        { remaining = true },
      },
    })

    originalEntryTable.display = function(entry)
      local tail, _ = utils.getPathAndTail(entry.filename)
      local tailForDisplay = tail .. ' '
      local pathToDisplay = telescopeUtilities.transform_path({
        path_display = { shorten = { num = 2, exclude = { -2, -1 } }, 'truncate' },
      }, entry.value.filename)

      return displayer({
        string.format('%s', kind_icons.icons[(entry.symbol_type:lower():gsub('^%l', string.upper))]),
        { entry.symbol_type:lower(), 'TelescopeResultsVariable' },
        { entry.symbol_name, 'TelescopeResultsConstant' },
        tailForDisplay,
        { pathToDisplay, 'TelescopeResultsComment' },
      })
    end

    return originalEntryTable
  end

  require('telescope.builtin').lsp_dynamic_workspace_symbols(options)
end

function M.lsp_references(opts)
  if opts ~= nil and type(opts) ~= 'table' then
    print('Options must be a table.')
    return
  end

  local options = opts or {}

  local originalEntryMaker = telescopeMakeEntryModule.gen_from_quickfix(options)

  options.entry_maker = function(line)
    local originalEntryTable = originalEntryMaker(line)

    local displayer = telescopeEntryDisplayModule.create({
      separator = ' ', -- Telescope will use this separator between each entry item
      items = {
        { width = utils.fileTypeIconWidth },
        { width = nil },
        { remaining = true },
      },
    })

    originalEntryTable.display = function(entry)
      local tail, pathToDisplay = utils.getPathAndTail(entry.filename)
      local tailForDisplay = tail .. ' '
      local icon, iconHighlight = telescopeUtilities.get_devicons(tail)
      local coordinates = string.format('  %s:%s ', entry.lnum, entry.col)

      return displayer({
        { icon, iconHighlight },
        tailForDisplay .. coordinates,
        { pathToDisplay, 'TelescopeResultsComment' },
      })
    end

    return originalEntryTable
  end

  require('telescope.builtin').lsp_references(options)
end

return {
  document_symbols = M.document_symbols,
  workspace_symbols = M.workspace_symbols,
  lsp_references = M.lsp_references,
}
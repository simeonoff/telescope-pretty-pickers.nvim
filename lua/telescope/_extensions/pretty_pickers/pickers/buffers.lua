local utils = require('telescope._extensions.pretty_pickers.utils')
local telescopeUtilities = require('telescope.utils')
local telescopeMakeEntryModule = require('telescope.make_entry')
local telescopeEntryDisplayModule = require('telescope.pickers.entry_display')

local M = {}

function M.buffers(opts)
  if opts ~= nil and type(opts) ~= 'table' then
    print('Options must be a table.')
    return
  end

  local options = opts or {}

  local originalEntryMaker = telescopeMakeEntryModule.gen_from_buffer(options)

  options.entry_maker = function(line)
    local originalEntryTable = originalEntryMaker(line)

    local displayer = telescopeEntryDisplayModule.create({
      separator = ' ',
      items = {
        { width = utils.fileTypeIconWidth },
        { width = nil },
        { width = nil },
        { remaining = true },
      },
    })

    originalEntryTable.display = function(entry)
      local tail, path = utils.getPathAndTail(entry.filename)
      local tailForDisplay = tail .. ' '
      local icon, iconHighlight = telescopeUtilities.get_devicons(tail)

      return displayer({
        { icon, iconHighlight },
        tailForDisplay,
        { '(' .. entry.bufnr .. ')', 'TelescopeResultsNumber' },
        { path, 'TelescopeResultsComment' },
      })
    end

    return originalEntryTable
  end

  require('telescope.builtin').buffers(options)
end

return M.buffers
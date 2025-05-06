local utils = require('telescope._extensions.pretty_pickers.utils')
local telescopeUtilities = require('telescope.utils')
local telescopeMakeEntryModule = require('telescope.make_entry')
local telescopeEntryDisplayModule = require('telescope.pickers.entry_display')

local M = {}

function M.files(opts)
  -- Parameter integrity check
  if type(opts) ~= 'table' or opts.picker == nil then
    print("Incorrect argument format. Correct format is: { picker = 'desiredPicker', (optional) options = { ... } }")

    -- Avoid further computation
    return
  end

  -- Ensure 'options' integrity
  local options = opts.options or {}

  -- Use Telescope's existing function to obtain a default 'entry_maker' function
  local originalEntryMaker = telescopeMakeEntryModule.gen_from_file(options)

  options.entry_maker = function(line)
    -- Generate the Original Entry table
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
      -- Get the Tail and the Path to display
      local tail, pathToDisplay = utils.getPathAndTail(entry.value)

      -- Add an extra space to the tail so that it looks nicely separated from the path
      local tailForDisplay = tail .. ' '

      -- Get the Icon with its corresponding Highlight information
      local icon, iconHighlight = telescopeUtilities.get_devicons(tail)

      return displayer({
        { icon, iconHighlight },
        tailForDisplay,
        { pathToDisplay, 'TelescopeResultsComment' },
      })
    end

    return originalEntryTable
  end

  -- Check which file picker was requested and open it with its associated options
  if opts.picker == 'find_files' then
    require('telescope.builtin').find_files(options)
  elseif opts.picker == 'git_files' then
    require('telescope.builtin').git_files(options)
  elseif opts.picker == 'oldfiles' then
    require('telescope.builtin').oldfiles(options)
  elseif opts.picker == '' then
    print('Picker was not specified')
  else
    print('Picker is not supported by Pretty Find Files')
  end
end

return M.files
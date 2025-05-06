local utils = require('telescope._extensions.pretty_pickers.utils')
local telescopeUtilities = require('telescope.utils')
local telescopeMakeEntryModule = require('telescope.make_entry')
local telescopeEntryDisplayModule = require('telescope.pickers.entry_display')

local M = {}

function M.grep(opts)
  -- Parameter integrity check
  if type(opts) ~= 'table' or opts.picker == nil then
    print("Incorrect argument format. Correct format is: { picker = 'desiredPicker', (optional) options = { ... } }")

    -- Avoid further computation
    return
  end

  -- Ensure 'options' integrity
  local options = opts.options or {}

  -- Use Telescope's existing function to obtain a default 'entry_maker' function
  local originalEntryMaker = telescopeMakeEntryModule.gen_from_vimgrep(options)

  options.entry_maker = function(line)
    -- Generate the Original Entry table
    local originalEntryTable = originalEntryMaker(line)

    local displayer = telescopeEntryDisplayModule.create({
      separator = ' ', -- Telescope will use this separator between each entry item
      items = {
        { width = utils.fileTypeIconWidth },
        { width = nil },
        { width = nil }, -- Maximum path size, keep it short
        { remaining = true },
      },
    })

    originalEntryTable.display = function(entry)
      ---- Get File columns data ----
      -------------------------------

      -- Get the Tail and the Path to display
      local tail, pathToDisplay = utils.getPathAndTail(entry.filename)

      -- Get the Icon with its corresponding Highlight information
      local icon, iconHighlight = telescopeUtilities.get_devicons(tail)

      ---- Format Text for display ----
      ---------------------------------

      -- Add coordinates if required by 'options'
      local coordinates = ''

      if not options.disable_coordinates then
        if entry.lnum then
          if entry.col then
            coordinates = string.format(' -> %s:%s', entry.lnum, entry.col)
          else
            coordinates = string.format(' -> %s', entry.lnum)
          end
        end
      end

      -- Append coordinates to tail
      tail = tail .. coordinates

      -- Add an extra space to the tail so that it looks nicely separated from the path
      local tailForDisplay = tail .. ' '

      -- Encode text if necessary
      local text = options.file_encoding and vim.iconv(entry.text, options.file_encoding, 'utf8') or entry.text

      return displayer({
        { icon, iconHighlight },
        tailForDisplay,
        { pathToDisplay, 'TelescopeResultsComment' },
        text,
      })
    end

    return originalEntryTable
  end

  -- Check which grep picker was requested and open it with its associated options
  if opts.picker == 'live_grep' then
    require('telescope.builtin').live_grep(options)
  elseif opts.picker == 'grep_string' then
    require('telescope.builtin').grep_string(options)
  elseif opts.picker == '' then
    print('Picker was not specified')
  else
    print('Picker is not supported by Pretty Grep Picker')
  end
end

return M.grep
local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
  vim.notify(
    'Telescope Pretty Pickers requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)',
    vim.log.levels.WARN
  )
  return
end

-- Dependencies check
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
  -- Store Utilities we'll use frequently
  local action_state = require('telescope.actions.state')
  -- local action_utils = require('telescope.actions.utils')
  local telescopeUtilities = require('telescope.utils')
  local telescopeMakeEntryModule = require('telescope.make_entry')
  local plenaryStrings = require('plenary.strings')
  local devIcons = require('nvim-web-devicons')
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local telescopeEntryDisplayModule = require('telescope.pickers.entry_display')
  local conf = require('telescope.config').values

  -- Safely require kind icons
  local kind_icons = require('kind')

  -- Obtain Filename icon width
  local fileTypeIconWidth = plenaryStrings.strdisplaywidth(devIcons.get_icon('fname', { default = true }))

  -- Helper functions
  function pretty_pickers.getPathAndTail(fileName)
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

  -- Function to get buffer number by full file path
  local function get_buffer_number_by_path(filepath)
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name == filepath then return bufnr end
    end
    return nil
  end

  -- Implementation of all the picker functions
  function pretty_pickers.files(opts)
    -- Parameter integrity check
    if type(opts) ~= 'table' or opts.picker == nil then
      print("Incorrect argument format. Correct format is: { picker = 'desiredPicker', (optional) options = { ... } }")

      -- Avoid further computation
      return
    end

    -- Ensure 'options' integrity
    local options = opts.options or {}

    -- Use Telescope's existing function to obtain a default 'entry_maker' function
    -- ----------------------------------------------------------------------------
    -- INSIGHT: Because calling this function effectively returns an 'entry_maker' function that is ready to
    --          handle entry creation, we can later call it to obtain the final entry table, which will
    --          ultimately be used by Telescope to display the entry by executing its 'display' key function.
    --          This reduces our work by only having to replace the 'display' function in said table instead
    --          of having to manipulate the rest of the data too.
    local originalEntryMaker = telescopeMakeEntryModule.gen_from_file(options)

    -- INSIGHT: 'entry_maker' is the hardcoded name of the option Telescope reads to obtain the function that
    --          will generate each entry.
    -- INSIGHT: The paramenter 'line' is the actual data to be displayed by the picker, however, its form is
    --          raw (type 'any) and must be transformed into an entry table.
    options.entry_maker = function(line)
      -- Generate the Original Entry table
      local originalEntryTable = originalEntryMaker(line)

      -- INSIGHT: An "entry display" is an abstract concept that defines the "container" within which data
      --          will be displayed inside the picker, this means that we must define options that define
      --          its dimensions, like, for example, its width.
      local displayer = telescopeEntryDisplayModule.create({
        separator = ' ', -- Telescope will use this separator between each entry item
        items = {
          { width = fileTypeIconWidth },
          { width = nil },
          { remaining = true },
        },
      })

      -- LIFECYCLE: At this point the "displayer" has been created by the create() method, which has in turn
      --            returned a function. This means that we can now call said function by using the
      --            'displayer' variable and pass it actual entry values so that it will, in turn, output
      --            the entry for display.
      --
      -- INSIGHT: We now have to replace the 'display' key in the original entry table to modify the way it
      --          is displayed.
      -- INSIGHT: The 'entry' is the same Original Entry Table but is is passed to the 'display()' function
      --          later on the program execution, most likely when the actual display is made, which could
      --          be deferred to allow lazy loading.
      --
      -- HELP: Read the 'make_entry.lua' file for more info on how all of this works
      originalEntryTable.display = function(entry)
        -- Get the Tail and the Path to display
        local tail, pathToDisplay = pretty_pickers.getPathAndTail(entry.value)

        -- Add an extra space to the tail so that it looks nicely separated from the path
        local tailForDisplay = tail .. ' '

        -- Get the Icon with its corresponding Highlight information
        local icon, iconHighlight = telescopeUtilities.get_devicons(tail)

        -- INSIGHT: This return value should be a tuple of 2, where the first value is the actual value
        --          and the second one is the highlight information, this will be done by the displayer
        --          internally and return in the correct format.
        return displayer({
          { icon, iconHighlight },
          tailForDisplay,
          { pathToDisplay, 'TelescopeResultsComment' },
        })
      end

      return originalEntryTable
    end

    -- Finally, check which file picker was requested and open it with its associated options
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
    -- Your existing prettyFilesPicker function implementation
    -- Renamed for consistency
  end

  function pretty_pickers.grep(opts)
    -- Parameter integrity check
    if type(opts) ~= 'table' or opts.picker == nil then
      print("Incorrect argument format. Correct format is: { picker = 'desiredPicker', (optional) options = { ... } }")

      -- Avoid further computation
      return
    end

    -- Ensure 'options' integrity
    local options = opts.options or {}

    -- Use Telescope's existing function to obtain a default 'entry_maker' function
    -- ----------------------------------------------------------------------------
    -- INSIGHT: Because calling this function effectively returns an 'entry_maker' function that is ready to
    --          handle entry creation, we can later call it to obtain the final entry table, which will
    --          ultimately be used by Telescope to display the entry by executing its 'display' key function.
    --          This reduces our work by only having to replace the 'display' function in said table instead
    --          of having to manipulate the rest of the data too.
    local originalEntryMaker = telescopeMakeEntryModule.gen_from_vimgrep(options)

    -- INSIGHT: 'entry_maker' is the hardcoded name of the option Telescope reads to obtain the function that
    --          will generate each entry.
    -- INSIGHT: The paramenter 'line' is the actual data to be displayed by the picker, however, its form is
    --          raw (type 'any) and must be transformed into an entry table.
    options.entry_maker = function(line)
      -- Generate the Original Entry table
      local originalEntryTable = originalEntryMaker(line)

      -- INSIGHT: An "entry display" is an abstract concept that defines the "container" within which data
      --          will be displayed inside the picker, this means that we must define options that define
      --          its dimensions, like, for example, its width.
      local displayer = telescopeEntryDisplayModule.create({
        separator = ' ', -- Telescope will use this separator between each entry item
        items = {
          { width = fileTypeIconWidth },
          { width = nil },
          { width = nil }, -- Maximum path size, keep it short
          { remaining = true },
        },
      })

      -- LIFECYCLE: At this point the "displayer" has been created by the create() method, which has in turn
      --            returned a function. This means that we can now call said function by using the
      --            'displayer' variable and pass it actual entry values so that it will, in turn, output
      --            the entry for display.
      --
      -- INSIGHT: We now have to replace the 'display' key in the original entry table to modify the way it
      --          is displayed.
      -- INSIGHT: The 'entry' is the same Original Entry Table but is is passed to the 'display()' function
      --          later on the program execution, most likely when the actual display is made, which could
      --          be deferred to allow lazy loading.
      --
      -- HELP: Read the 'make_entry.lua' file for more info on how all of this works
      originalEntryTable.display = function(entry)
        ---- Get File columns data ----
        -------------------------------

        -- Get the Tail and the Path to display
        local tail, pathToDisplay = pretty_pickers.getPathAndTail(entry.filename)

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

        -- INSIGHT: This return value should be a tuple of 2, where the first value is the actual value
        --          and the second one is the highlight information, this will be done by the displayer
        --          internally and return in the correct format.
        return displayer({
          { icon, iconHighlight },
          tailForDisplay,
          { pathToDisplay, 'TelescopeResultsComment' },
          text,
        })
      end

      return originalEntryTable
    end

    -- Finally, check which file picker was requested and open it with its associated options
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

  function pretty_pickers.document_symbols(opts)
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
          { width = fileTypeIconWidth },
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

  function pretty_pickers.workspace_symbols(opts)
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
          { width = fileTypeIconWidth },
          { width = 15 },
          { width = 30 },
          { width = nil },
          { remaining = true },
        },
      })

      originalEntryTable.display = function(entry)
        local tail, _ = pretty_pickers.getPathAndTail(entry.filename)
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

  function pretty_pickers.lsp_references(opts)
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
          { width = fileTypeIconWidth },
          { width = nil },
          { remaining = true },
        },
      })

      originalEntryTable.display = function(entry)
        local tail, pathToDisplay = pretty_pickers.getPathAndTail(entry.filename)
        local tailForDisplay = tail .. ' '
        local icon, iconHighlight = telescopeUtilities.get_devicons(tail)
        local coordinates = string.format('  %s:%s ', entry.lnum, entry.col)

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

  function pretty_pickers.buffers(opts)
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
          { width = fileTypeIconWidth },
          { width = nil },
          { width = nil },
          { remaining = true },
        },
      })

      originalEntryTable.display = function(entry)
        local tail, path = pretty_pickers.getPathAndTail(entry.filename)
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

  function pretty_pickers.grapple(opts)
    local Grapple = require('grapple')

    if opts ~= nil and type(opts) ~= 'table' then
      print('Options must be a table.')
      return
    end

    local options = opts or {}

    local generate_finder = function()
      local tags, err = Grapple.tags()

      if not tags then
        ---@diagnostic disable-next-line: param-type-mismatch
        return vim.notify(err, vim.log.levels.ERROR)
      end

      local results = {}
      for i, tag in ipairs(tags) do
        ---@class grapple.telescope.result
        local result = {
          i,
          tag.path,
          tag.cursor and tag.cursor[1],
          tag.cursor and tag.cursor[2],
        }

        table.insert(results, result)
      end

      local displayer = telescopeEntryDisplayModule.create({
        separator = ' ',
        items = {
          { width = fileTypeIconWidth },
          { width = nil },
          { remaining = true },
        },
      })

      return finders.new_table({
        results = results,

        ---@param result grapple.telescope.result
        entry_maker = function(result)
          local filename = result[2]
          local lnum = result[3]

          local entry = {
            value = result,
            ordinal = filename,
            filename = filename,
            lnum = lnum,
            display = function(entry)
              local tail, pathToDisplay = pretty_pickers.getPathAndTail(entry.value[2])
              local icon, iconHighlight = telescopeUtilities.get_devicons(tail)
              local tailForDisplay = string.len(tail) > 0 and tail or 'window'
              local bufnr = get_buffer_number_by_path(filename)
              local modified = vim.api.nvim_get_option_value('modified', { buf = bufnr })

              return displayer({
                { icon, iconHighlight },
                { tailForDisplay .. ' ', bufnr and modified and 'TelescopeResultsNumber' or '' },
                { pathToDisplay, 'TelescopeResultsComment' },
              })
            end,
          }

          return entry
        end,
      })
    end

    local function delete_tag(prompt_bufnr)
      local selection = action_state.get_selected_entry()

      Grapple.untag({ path = selection.filename })

      local current_picker = action_state.get_current_picker(prompt_bufnr)
      current_picker:refresh(generate_finder(), { reset_prompt = true })
    end

    pickers
      .new(options, {
        prompt_title = 'Grapple',
        finder = generate_finder(),
        sorter = conf.generic_sorter({}),
        previewer = conf.file_previewer({}),
        results_title = 'Grapple Tags',
        attach_mappings = function(_, map)
          map('i', '<C-X>', delete_tag)
          map('n', '<C-X>', delete_tag)
          return true
        end,
      })
      :find()
  end
end

-- Register the extension with telescope
return telescope.register_extension({
  exports = {
    files = pretty_pickers.files,
    grep = pretty_pickers.grep,
    document_symbols = pretty_pickers.document_symbols,
    workspace_symbols = pretty_pickers.workspace_symbols,
    lsp_references = pretty_pickers.lsp_references,
    buffers = pretty_pickers.buffers,
    grapple = pretty_pickers.grapple,
  },
})

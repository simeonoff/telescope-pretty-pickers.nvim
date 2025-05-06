local utils = require('telescope._extensions.pretty_pickers.utils')
local telescopeUtilities = require('telescope.utils')
local action_state = require('telescope.actions.state')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local telescopeEntryDisplayModule = require('telescope.pickers.entry_display')
local conf = require('telescope.config').values

local M = {}

function M.grapple(opts)
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
        { width = utils.fileTypeIconWidth },
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
            local tail, pathToDisplay = utils.getPathAndTail(entry.value[2])
            local icon, iconHighlight = telescopeUtilities.get_devicons(tail)
            local tailForDisplay = string.len(tail) > 0 and tail or 'window'
            local bufnr = utils.get_buffer_number_by_path(filename)
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

return M.grapple
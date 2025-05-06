# telescope-pretty-pickers.nvim

> **Note**: This extension is in initial development and has primarily been created for my personal use.

A Neovim plugin that adds nicely formatted pickers to [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim), enhancing the display of various telescope pickers with better formatting and additional details.

## Features

- Improved file pickers with better path/filename separation and icons
- Enhanced grep results with easier-to-read file locations
- Beautifully formatted LSP symbol pickers with proper icons
- Support for [Grapple](https://github.com/cbochs/grapple.nvim) integration
- Better buffer display with clear indicators

## Installation

Install with your favorite package manager:

### Lazy

```lua
return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'cbochs/grapple.nvim',
    'simeonoff/telescope-pretty-pickers.nvim',
  },
  config = function()
    local telescope = require('telescope')
    
    telescope.setup({
      -- your telescope config here
    })
    
    -- Load the extension
    telescope.load_extension('pretty_pickers')
  end,
}
```

## Usage

This extension enhances several common telescope pickers. Here's how to use them:

### File Pickers

```lua
-- Find files with pretty formatting
telescape.extensions.pretty_pickers.files({
  picker = 'find_files', -- Can be 'find_files', 'git_files', or 'oldfiles'
  options = { -- Standard telescope options
    prompt_title = 'Project Files',
    cwd = vim.fn.getcwd(),
  },
})
```

### Grep Pickers

```lua
-- Search with live_grep
telescape.extensions.pretty_pickers.grep({
  picker = 'live_grep', -- Can be 'live_grep' or 'grep_string'
  options = { -- Standard telescope options
    prompt_title = 'Search Text',
  },
})
```

### LSP Pickers

```lua
-- Document symbols
telescape.extensions.pretty_pickers.document_symbols({
  prompt_title = 'Document Symbols',
})

-- Workspace symbols
telescape.extensions.pretty_pickers.workspace_symbols({
  prompt_title = 'Workspace Symbols',
})

-- LSP references
telescape.extensions.pretty_pickers.lsp_references({
  prompt_title = 'LSP References',
})
```

### Buffer Picker

```lua
-- List buffers with pretty formatting
telescape.extensions.pretty_pickers.buffers({
  prompt_title = 'Buffers',
})
```

### Grapple Integration

```lua
-- Pick from Grapple tags
telescape.extensions.pretty_pickers.grapple({
  prompt_title = 'Grapple Tags',
})
```

## Example Configuration

A more complete example based on my personal configuration:

```lua
local telescope = require('telescope')
local utils = require('utils') -- My utility module with get_root() function

-- Custom picker functions
local recent_files = function()
  telescope.extensions.pretty_pickers.files({
    picker = 'oldfiles',
    options = {
      prompt_title = 'Recent Files',
      cwd = utils.get_root(),
      cwd_only = true,
    },
  })
end

local project_files = function()
  local opts = {}

  if vim.uv.fs_stat('.git') then
    opts.show_untracked = true
    opts.prompt_title = 'Git Files'

    telescope.extensions.pretty_pickers.files({
      picker = 'git_files',
      options = opts,
    })
  else
    local client = vim.lsp.get_clients()[1]

    if client then opts.cwd = client.config.root_dir end

    telescope.extensions.pretty_pickers.files({
      prompt_title = 'Project Files',
      picker = 'find_files',
      options = opts,
    })
  end
end

-- Keymaps
vim.keymap.set('n', '<leader>f', project_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>r', recent_files, { desc = 'Recent files' })
```

## Requirements

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)
- [grapple.nvim](https://github.com/cbochs/grapple.nvim) (optional, for grapple picker)

## License

MIT

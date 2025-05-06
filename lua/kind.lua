local M = {}

M.icons = {
  Namespace = '  ',
  Text = '  ',
  Method = '󰡱  ',
  Function = '󰡱 ',
  Constructor = '  ',
  Field = '  ',
  Variable = '  ',
  Class = '  ',
  Interface = '  ',
  Module = ' ',
  Property = '  ',
  Unit = '  ',
  Value = '  ',
  Enum = '  ',
  Keyword = '  ',
  Key = ' ',
  Snippet = ' ',
  Color = '  ',
  File = '  ',
  Reference = ' ',
  Folder = '  ',
  EnumMember = ' ',
  Constant = '  ',
  Struct = '  ',
  Event = '  ',
  Operator = '  ',
  TypeParameter = '  ',
  Table = ' ',
  Object = ' ',
  Tag = ' ',
  Array = '[]',
  Boolean = ' ',
  Number = ' ',
  Null = '  ',
  String = '  ',
  Calendar = ' ',
  Watch = '  ',
  Package = ' ',
  Copilot = ' ',
  Suggestion = ' ',
  Codeium = '󰘦 ',
}

M.get_icon = function(kind)
  for key, value in pairs(M.icons) do
    if key == kind then return value end
  end
  return nil
end

M.cmp_format = function()
  return function(entry, vim_item)
    -- vim_item.kind = string.format("%s %s", M.icons[vim_item.kind], vim_item.kind)
    vim_item.kind = M.icons[vim_item.kind]

    vim_item.menu = ({
      buffer = '[Buffer]',
      nvim_lsp = '[LSP]',
      luasnip = '[Snippet]',
      nvim_lua = '[Lua]',
      latex_symbols = '[LaTeX]',
      copilot = '[Copilot]',
      codeium = '[Codeium]',
    })[entry.source.name]

    return vim_item
  end
end

M.diagnostic_signs = {
  error = '󰅚 ',
  warn = '󰗖 ',
  hint = '󱇮 ',
  info = '󰰅 ',
}

M.diff_icons = {
  added = '󰐙 ',
  modified = '󰻃 ',
  removed = '󰍷 ',
}

return M

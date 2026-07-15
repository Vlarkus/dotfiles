-- Extra language support beyond LazyVim's bundled extras.
-- Covers things without a dedicated LazyVim extra: assembly, robotics XML
-- (URDF/xacro/launch files), and web HTML/CSS.

return {
  -- Treesitter parsers (syntax + indentation) for non-extra languages
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "asm",  -- assembly
        "xml",  -- robotics: urdf / xacro / launch / package.xml
        "html",
        "css",
        "bash",
      })
    end,
  },

  -- HTML / CSS language servers (web). Auto-installed via Mason on first use.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        html = {},
        cssls = {},
      },
    },
  },
}

-- Catppuccin Mocha everywhere.
--
-- The rest of this setup is already Mocha (tmux.conf, alacritty.toml, the
-- Ptyxis palette, claude/statusline.sh), so nvim was the odd one out on
-- LazyVim's default tokyonight-moon.
--
-- catppuccin ships with LazyVim, so this pulls in no new plugin.

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      integrations = {
        treesitter = true,
        native_lsp = { enabled = true },
        telescope = true,
        which_key = true,
        gitsigns = true,
        mason = true,
        markdown = true,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin-mocha" },
  },
}

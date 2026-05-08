-- ============================================================================
-- Colorscheme — `everforest`. Set after vim.pack.add has run so the plugin
-- is on runtimepath. We override `LazyVim`'s old approach (set as opt) since
-- there is no LazyVim anymore — direct setup() + colorscheme call.
-- ============================================================================

local ok, everforest = pcall(require, 'everforest')
if not ok then return end

everforest.setup({
  background = 'medium',     -- soft | medium | hard
  italics = true,
  ui_contrast = 'low',
  diagnostic_text_highlight = true,
  diagnostic_line_highlight = false,
  spell_foreground = false,
})

-- Apply. Wrap in pcall so a missing colorscheme doesn't abort startup
-- (e.g. on first run before vim.pack has finished cloning).
pcall(vim.cmd.colorscheme, 'everforest')

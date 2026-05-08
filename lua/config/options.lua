-- ============================================================================
-- Editor options. Values mirror what kickstart.nvim sets, with extras for
-- a daily-driver workflow. Each block has a comment explaining the *why*.
-- ============================================================================

local opt = vim.opt

-- Line numbers: absolute on the cursor line, relative elsewhere — fastest
-- way to jump with `5j`/`12k` motions without counting from line 1.
opt.number = true
opt.relativenumber = true

-- System clipboard integration. macOS: `osascript`/`pbcopy` already wired by nvim.
-- We schedule the option write so startup isn't blocked on clipboard provider lookup.
vim.schedule(function() opt.clipboard = 'unnamedplus' end)

-- Search: case-insensitive unless query has uppercase ("smart").
opt.ignorecase = true
opt.smartcase = true

-- Wrapped lines indent visually under their start column — readable prose.
opt.breakindent = true

-- Persistent undo across sessions; lives in <data>/undo/.
opt.undofile = true

-- Keep some context around the cursor when scrolling.
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Show diagnostics column always so text doesn't shift when one appears.
opt.signcolumn = 'yes'

-- Faster CursorHold (used by LSP for hover popups, gitsigns blame, etc.).
opt.updatetime = 250

-- which-key-style timeout for partial mappings.
opt.timeoutlen = 300

-- Splits: open right and below by default; less surprising than the vim defaults.
opt.splitright = true
opt.splitbelow = true

-- Show special characters: tabs as "→ ", trailing spaces as "·", non-breaking as "␣".
opt.list = true
opt.listchars = { tab = '→ ', trail = '·', nbsp = '␣' }

-- Live preview of substitutions in a split (`:%s/foo/bar` — see what'd change).
opt.inccommand = 'split'

-- Highlight the cursor line so the cursor is locatable in long files.
opt.cursorline = true

-- True color — required by everforest and most modern colorschemes.
opt.termguicolors = true

-- Reasonable tabbing defaults; ftplugins override per language.
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

-- No swapfiles; we have undofile + git for recovery.
opt.swapfile = false

-- Disable some built-in plugins we don't use to shave a millisecond or two.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

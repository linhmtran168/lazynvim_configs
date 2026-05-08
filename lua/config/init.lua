-- ============================================================================
-- Boot orchestrator — the single entry point that wires the whole config.
-- Read top-to-bottom: each step's order matters. See the design spec §5.2.
-- ============================================================================

-- 1. Set leader BEFORE any plugin spec evaluates `keys = { ... }`.
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- 2. Editor options first so plugin setup() observes the right values.
require('config.options')

-- 3. Aggregate language modules (pure data; no side effects).
--    `config.lang` reads every lua/plugins/lang/*.lua and merges them
--    into a single table consumed by lsp / coding / treesitter modules.
local lang = require('config.lang')

-- 4. Install / update plugins via vim.pack. Blocking on first run while
--    repos are git-cloned. Subsequent runs: ~instant, no network.
require('config.pack')

-- 5. Plugin modules in load order. Each `require` is pcall-wrapped so a
--    single broken module surfaces an error but doesn't abort startup.
local function load(mod)
  local ok, err = pcall(require, mod)
  if not ok then
    vim.notify(('module %s failed: %s'):format(mod, err), vim.log.levels.ERROR)
  end
end

load('plugins.colorscheme')   -- first so subsequent setups hash correct hl groups
load('plugins.treesitter')    -- early so plugins assuming TS find it ready
load('plugins.ui')
load('plugins.editor')
load('plugins.coding')
load('plugins.picker')
load('plugins.git')
load('plugins.ai')
load('plugins.lsp')           -- last among plugins; reads `lang` for servers

-- 6. Keymaps after plugins so user commands defined by plugins exist.
require('config.keymaps')
require('config.autocmds')

-- Expose `lang` for diagnostic poking via `:lua = require('config.lang')`.
return { lang = lang }

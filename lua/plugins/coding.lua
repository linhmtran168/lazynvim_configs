return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "super-tab",
    },
    completion = {
      list = {
        preselect = function(_)
          return not require("blink.cmp").snippet_active({ direction = 1 })
        end,
      },
    },
  },
}

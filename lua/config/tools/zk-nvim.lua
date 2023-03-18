-- https://github.com/mickael-menu/zk-nvim
local api = require("utils.api")

local M = {
    requires = {
        "zk",
    },
}

function M.before()
    M.register_key()
end

function M.load()
    require("zk").setup({
      -- can be "telescope", "fzf" or "select" (`vim.ui.select`)
      -- it's recommended to use "telescope" or "fzf"
      picker = "telescope",

      lsp = {
        -- `config` is passed to `vim.lsp.start_client(config)`
        config = {
          cmd = { "zk", "lsp" },
          name = "zk",
          -- on_attach = ...
          -- etc, see `:h vim.lsp.start_client()`
        },

        -- automatically attach buffers in a zk notebook that match the given filetypes
        auto_attach = {
          enabled = true,
          filetypes = { "markdown" },
        },
      },
    })
end

function M.after()
end

function M.register_key()
    local opts = { noremap=true, silent=false }
    api.map.bulk_register({
        {
            mode = { "n" },
            lhs = "<leader>zn",
            rhs = function()
                require("zk").new( { title = vim.fn.input('Title: ') } );
            end,
            options = opts,
            description = "Create a new note after asking for it's title.",
        },
        {
            mode = { "n" },
            lhs = "<leader>zo",
            rhs = function()
                require("zk.commands").get("ZkNotes")({ sort = { 'modified' } });
            end,
            options = opts,
            description = "Open Notes.",
        },
        {
            mode = { "n" },
            lhs = "<leader>zt",
            rhs = "<cmd>ZkTags<cr>",
            options = opts,
            description = "Open notes associated with tags.",
        },
        {
            mode = { "n" },
            lhs = "<leader>zf",
            rhs = function()
                require("zk.commands").get("ZkNotes")({ sort = { 'modified' }, match = { vim.fn.input('Search') } });
            end,
            options = opts,
            description = "Search for notes matching a given query.",
        },
        {
            mode = { "v" },
            lhs = "<leader>zf",
            rhs = "<cmd>ZkMatch<cr>",
            options = opts,
            description = "Search for notes matching the current visual selection.",
        },
    })
end

return M

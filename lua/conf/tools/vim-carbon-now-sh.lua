-- https://github.com/kristijanhusak/vim-carbon-now-sh

local api = require("utils.api")

local M = {
    _viml = true,
}

function M.before() end

function M.load()
    M.register_key()
end

function M.after() end

function M.register_key()
    api.map.bulk_register({
        {
            mode = { "v" },
            lhs = "<leader>ci",
            rhs = ":CarbonNowSh<cr>",
            options = { silent = true },
            description = "Code screenshot",
        },
        {
            mode = { "n" },
            lhs = "<leader>ci",
            rhs = "mtggVG:CarbonNowSh<cr>`t",
            options = { silent = true },
            description = "Code screenshot",
        },
    })
end

return M
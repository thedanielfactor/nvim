-- https://github.com/folke/trouble.nvim

local M = {
    requires = {
        "trouble",
    },
}

function M.before() end

function M.load()
    M.trouble.setup({{
    }})
end

function M.after() end

return M

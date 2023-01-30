local public = require("utils.public")
local options = require("core.options")
local setting = require("core.setting")
local icons = public.get_icons_group("diagnostic", true)

local M = {
    filetype = {
        hover = "lsp-hover",
        signatureHelp = "lsp-signature-help",
    },
}

function M.lsp_hover(_, result, ctx, config)
    local bufnr, winner = vim.lsp.handlers.hover(_, result, ctx, config)

    if bufnr and winner then
        vim.api.nvim_buf_set_option(bufnr, "filetype", config.filetype)
        return bufnr, winner
    end
end

function M.lsp_signature_help(_, result, ctx, config)
    local bufnr, winner = vim.lsp.handlers.signature_help(_, result, ctx, config)

    local current_cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    local ok, window_height = pcall(vim.api.nvim_win_get_height, winner)

    if not ok then
        return
    end

    if current_cursor_line > window_height + 2 then
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.api.nvim_win_set_config(winner, {
            anchor = "SW",
            relative = "cursor",
            row = 0,
            col = -1,
        })
    end

    if bufnr and winner then
        vim.api.nvim_buf_set_option(bufnr, "filetype", config.filetype)
        return bufnr, winner
    end
end

function M.basic_quick_set()
    M.lsp_handlers = {
        ["textDocument/hover"] = vim.lsp.with(M.lsp_hover, {
            border = options.float_border and "rounded" or "none",
            filetype = M.filetype.hover,
        }),
        ["textDocument/signatureHelp"] = vim.lsp.with(M.lsp_signature_help, {
            border = options.float_border and "rounded" or "none",
            filetype = M.filetype.signatureHelp,
        }),
    }

    M.capabilities = vim.lsp.protocol.make_client_capabilities()

    M.capabilities.textDocument.completion.completionItem = {
        documentationFormat = { "markdown", "plaintext" },
        snippetSupport = true,
        preselectSupport = true,
        insertReplaceSupport = true,
        labelDetailsSupport = true,
        deprecatedSupport = true,
        commitCharactersSupport = true,
        tagSupport = { valueSet = { 1 } },
        resolveSupport = {
            properties = {
                "documentation",
                "detail",
                "additionalTextEdits",
            },
        },
    }
end

function M.diagnostic_quick_set()
    vim.diagnostic.config({
        signs = true,
        underline = true,
        severity_sort = true,
        update_in_insert = false,
        float = { source = "always" },
        virtual_text = { prefix = "●", source = "always" },
    })

    for _type, icon in pairs(icons) do
        local hl = string.format("DiagnosticSign%s", _type)
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end
end

function M.lspconfig_ui_quick_set()
    require("lspconfig.ui.windows").default_options.border = options.float_border and "double" or "none"
end

function M.get_headlers(settings)
    return vim.tbl_deep_extend("force", M.lsp_handlers, settings.handlers or {})
end

function M.get_capabilities()
    return M.capabilities
end

function M.diagnostic_open_float()
    vim.diagnostic.open_float({ border = options.float_border and "rounded" or "none" })
end

function M.goto_next_diagnostic()
    vim.diagnostic.goto_next({ float = { border = options.float_border and "rounded" or "none" } })
end

function M.goto_prev_diagnostic()
    vim.diagnostic.goto_prev({ float = { border = options.float_border and "rounded" or "none" } })
end

function M.toggle_sigature_help()
    for _, opts in ipairs(public.get_all_window_buffer_filetype()) do
        if opts.buffer_filetype == M.filetype.signatureHelp then
            vim.api.nvim_win_close(opts.window_id, false)
            return
        end
    end
    vim.lsp.buf.signature_help()
end

function M.scroll_docs_to_up(map)
    return function()
        for _, opts in ipairs(public.get_all_window_buffer_filetype()) do
            if vim.tbl_contains(vim.tbl_values(M.filetype), opts.buffer_filetype) then
                local window_height = vim.api.nvim_win_get_height(opts.window_id)
                local cursor_line = vim.api.nvim_win_get_cursor(opts.window_id)[1]
                local buffer_total_line = vim.api.nvim_buf_line_count(opts.buffer_id)
                ---@diagnostic disable-next-line: redundant-parameter
                local win_first_line = vim.fn.line("w0", opts.window_id)

                if buffer_total_line <= window_height or cursor_line == 1 then
                    vim.api.nvim_echo({ { "Can't scroll up", "MoreMsg" } }, false, {})
                    return
                end

                vim.opt.scrolloff = 0

                if cursor_line > win_first_line then
                    if win_first_line - 5 > 1 then
                        vim.api.nvim_win_set_cursor(opts.window_id, { win_first_line - 5, 0 })
                    else
                        vim.api.nvim_win_set_cursor(opts.window_id, { 1, 0 })
                    end
                elseif cursor_line - 5 < 1 then
                    vim.api.nvim_win_set_cursor(opts.window_id, { 1, 0 })
                else
                    vim.api.nvim_win_set_cursor(opts.window_id, { cursor_line - 5, 0 })
                end

                vim.opt.scrolloff = setting.opt.scrolloff

                return
            end
        end

        local key = vim.api.nvim_replace_termcodes(map, true, false, true)
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.api.nvim_feedkeys(key, "n", true)
    end
end

function M.scroll_docs_to_down(map)
    return function()
        for _, opts in ipairs(public.get_all_window_buffer_filetype()) do
            if vim.tbl_contains(vim.tbl_values(M.filetype), opts.buffer_filetype) then
                local window_height = vim.api.nvim_win_get_height(opts.window_id)
                local cursor_line = vim.api.nvim_win_get_cursor(opts.window_id)[1]
                local buffer_total_line = vim.api.nvim_buf_line_count(opts.buffer_id)
                ---@diagnostic disable-next-line: redundant-parameter
                local window_last_line = vim.fn.line("w$", opts.window_id)

                if buffer_total_line <= window_height or cursor_line == buffer_total_line then
                    vim.api.nvim_echo({ { "Can't scroll down", "MoreMsg" } }, false, {})
                    return
                end

                vim.opt.scrolloff = 0

                if cursor_line < window_last_line then
                    if window_last_line + 5 < buffer_total_line then
                        vim.api.nvim_win_set_cursor(opts.window_id, { window_last_line + 5, 0 })
                    else
                        vim.api.nvim_win_set_cursor(opts.window_id, { buffer_total_line, 0 })
                    end
                elseif cursor_line + 5 >= buffer_total_line then
                    vim.api.nvim_win_set_cursor(opts.window_id, { buffer_total_line, 0 })
                else
                    vim.api.nvim_win_set_cursor(opts.window_id, { cursor_line + 5, 0 })
                end

                vim.opt.scrolloff = setting.opt.scrolloff

                return
            end
        end

        local key = vim.api.nvim_replace_termcodes(map, true, false, true)
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.api.nvim_feedkeys(key, "n", true)
    end
end


function M.begin()
    M.basic_quick_set()
    M.diagnostic_quick_set()
    M.lspconfig_ui_quick_set()
end

return M

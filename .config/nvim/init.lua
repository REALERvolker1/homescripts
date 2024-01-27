vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local opt = vim.opt

local vlk_tab_width = 4

opt.tabstop = vlk_tab_width
opt.expandtab = true
opt.shiftwidth = 0
opt.shiftround = true
opt.autoindent = true
opt.smartindent = true

opt.wrap = true
opt.scrolloff = 3
opt.termguicolors = true
opt.cursorline = true
opt.undofile = true

opt.number = true
opt.relativenumber = true
opt.numberwidth = 2
opt.showbreak = "↪ "

-- opt.mouse = null
opt.listchars = "trail:·,nbsp:◇,tab:→ ,extends:▸,precedes:◂"
opt.list = true
--vim.opt.listchars:append "space:⋅"
--vim.opt.listchars:append "eol:↴"
opt.foldmethod = "marker"
--opt.foldmethod = "syntax"
opt.foldcolumn = "1"
-- opt.foldlevel = 99
opt.foldenable = true

-- I have it so my nvim slicing/dicing clipboard works normally.
-- These are system clipboard shortcuts that are entirely isolated from the nvim clipboard.
-- These make neovim usable for text editing. I don't understand why they aren't the default.
-- Huge thanks to https://stackoverflow.com/a/76880300
vim.keymap.set({ "n", "v" }, "<C-c>", '"+y', { desc = "Ctrl-C copy to system clipboard" })
vim.keymap.set({ "n", "v" }, "<C-x>", '"+d', { desc = "Ctrl-X cut to system clipboard" })
vim.keymap.set({ "n", "v" }, "<C-v>", '"+p', { desc = "Ctrl-V paste into buffer" })

vim.keymap.set("i", "<C-v>", '<Esc>"+p', { desc = "Ctrl-V paste (from insert mode)" })

--: Be very cautious about enabling system clipboard!
--opt.clipboard = 'unnamed,unnamedplus'
opt.clipboard = ""
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
-- opt.lazyredraw = true

opt.showmode = true
vim.filetype.add({
    extension = {
        rasi = "rasi",
    },
})

-- try to detect filetype again
vim.keymap.set("n", "<leader>d", "<Cmd>filetype detect<CR>", { desc = "Try to autodetect the filetype again" })

-- set terminal-specific settings
local term = string.lower(vim.env.TERM or "")
local is_kitty = false

if term:match("kitty") then
    is_kitty = true
end
-- elseif term:match("alacritty") then
-- Fixes alacritty
vim.cmd([[
    augroup change_cursor
        au!
        au ExitPre * :set guicursor=a:ver90
    augroup END
]])

-- speedy loading
vim.loader.enable()

-- funny rainbow stuff I need for a few plugins
local rainbow_hl_config = {
    { key = "RainbowDelimiterRed", fg = "#E06C75" },
    { key = "RainbowDelimiterYellow", fg = "#E5C07B" },
    { key = "RainbowDelimiterBlue", fg = "#61AFEF" },
    { key = "RainbowDelimiterOrange", fg = "#D19A66" },
    { key = "RainbowDelimiterGreen", fg = "#98C379" },
    { key = "RainbowDelimiterViolet", fg = "#C678DD" },
    { key = "RainbowDelimiterCyan", fg = "#56B6C2" },
}
local delim_highlight = {}
for _, v in pairs(rainbow_hl_config) do
    table.insert(delim_highlight, v.key)
end

-- workaround for nvimtree showing up instead of alpha when invoked with no args
local nvim_tree_loaded = false

-- some plugins are very resource-intensive. I don't want them eating my battery up

local battery_status_path = "/sys/class/power_supply/BAT1/status"

-- TODO: Make this use the nvim-std api for this
local is_plugged = true
local fh = io.open(battery_status_path, "r")
if fh ~= nil then
    local content = fh:read("l")
    if content:lower() == "discharging" then
        is_plugged = false
    end
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)
local capabilities = nil

require("lazy").setup({
    {
        "numToStr/Comment.nvim",
        -- lazy = false,
        event = "BufEnter",
        opts = {
            padding = true,
            sticky = true,
            toggler = { line = "," },
        },
    },
    {
        "goolord/alpha-nvim",
        config = function()
            require("alpha").setup(require("alpha.themes.dashboard").config)
        end,
    },
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        opts = {
            lsp = {
                progress = {
                    enabled = false,
                },
                -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    -- ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
                },
            },
            health = {
                checker = true,
            },
            presets = {
                bottom_search = true,
            },
        },
        dependencies = {
            "MunifTanjim/nui.nvim",
            {
                "rcarriga/nvim-notify",
                opts = {
                    background_colour = "#000000",
                },
            },
        },
        init = function()
            vim.keymap.set("n", "<leader>nl", function()
                require("noice").cmd("last")
            end)

            vim.keymap.set("n", "<leader>nh", function()
                require("noice").cmd("history")
            end)
        end,
    },
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },
    {
        "olimorris/onedarkpro.nvim",
        lazy = false,
        opts = {
            theme = "onedark_vivid",
            options = {
                transparency = true,
                terminal_colors = false,
                bold = true,
                italic = true,
                underline = true,
                undercurl = true,
            },
            styles = {
                comments = "italic",
                keywords = "underline",
                constants = "bold",
                parameters = "italic",
            },
        },
        init = function()
            vim.cmd("colorscheme onedark_vivid")
        end,
    },
    {
        "mikesmithgh/kitty-scrollback.nvim",
        enabled = is_kitty,
        lazy = true,
        cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
        event = { "User KittyScrollbackLaunch" },
        config = function()
            require("kitty-scrollback").setup()
        end,
    },
    {
        "NvChad/nvim-colorizer.lua",
        dependencies = {
            {
                "m00qek/baleia.nvim",
                event = "VeryLazy",
            },
        },
        -- lazy = true,
        event = "VeryLazy",
        opts = {
            filetypes = { "*" },
            user_default_options = {
                RRGGBBAA = true,
                mode = "background",
            },
        },
    },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        init = function()
            opt.timeout = true
            opt.timeoutlen = 300
        end,
        opts = {},
    },
    {
        "kevinhwang91/nvim-hlslens",
        event = "BufEnter",
        opts = {
            -- clear highlight on cursor move
            calm_down = false,
            nearest_only = true,
        },
    },
    {
        "karb94/neoscroll.nvim",
        -- lazy = false,
        event = "BufEnter",
        opts = {
            easing_function = "quadratic",
        },
    },
    {
        "petertriho/nvim-scrollbar",
        event = "BufEnter",
        -- lazy = false,
        config = true,
    },
    {
        "chrisgrieser/nvim-spider",
        keys = {
            {
                "w",
                "<cmd>lua require('spider').motion('w')<CR>",
                mode = { "n", "o", "x" },
            },
            {
                "e",
                "<cmd>lua require('spider').motion('e')<CR>",
                mode = { "n", "o", "x" },
            },
            {
                "b",
                "<cmd>lua require('spider').motion('b')<CR>",
                mode = { "n", "o", "x" },
            },
        },
    },
    {
        "brenton-leighton/multiple-cursors.nvim",
        version = "*",
        opts = {},
        keys = {
            { "<M-Down>", "<Cmd>MultipleCursorsAddDown<CR>", mode = { "n", "i" }, desc = "Add multiple cursors down" },
            { "<M-j>", "<Cmd>MultipleCursorsAddDown<CR>", desc = "Add multiple cursors down" },
            { "<M-Up>", "<Cmd>MultipleCursorsAddUp<CR>", mode = { "n", "i" }, desc = "Add multiple cursors up" },
            { "<M-k>", "<Cmd>MultipleCursorsAddUp<CR>", desc = "Add multiple cursors up" },
            {
                "<M-LeftMouse>",
                "<Cmd>MultipleCursorsMouseAddDelete<CR>",
                mode = { "n", "i" },
                desc = "Add multiple cursors using the mouse",
            },
            {
                "<Leader>ca",
                "<Cmd>MultipleCursorsAddBySearch<CR>",
                mode = { "n", "x" },
                desc = "Add multiple cursors by search",
            },
            {
                "<Leader>cA",
                "<Cmd>MultipleCursorsAddBySearchV<CR>",
                mode = { "n", "x" },
                desc = "Add multiple cursors by searchV",
            },
        },
    },
    {
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        "nvim-telescope/telescope.nvim",
        lazy = true,
        init = function()
            -- default leader: \
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>fF", builtin.find_files, { desc = "Fuzzy-find files" })
            vim.keymap.set("n", "<leader>ff", builtin.current_buffer_fuzzy_find, { desc = "search for text" })
            vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "telescope buffers" })
            vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Keymaps" })
            vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "Search for a command" })
            vim.keymap.set("n", "<leader>fp", builtin.pickers, { desc = "All Telescope pickers" })
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Search for help" })
        end,
    },
    {
        "nvim-tree/nvim-tree.lua",
        config = true,
        init = function()
            nvim_tree_loaded = true
        end,
    },
    {
        "hrsh7th/nvim-cmp",
        -- lazy = true,
        dependencies = {
            "hrsh7th/cmp-nvim-lua",
            "FelipeLema/cmp-async-path",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-cmdline",
            {
                "garyhurtz/cmp_kitty",
                init = function()
                    require("cmp_kitty"):setup()
                end,
            },
            {
                "tamago324/cmp-zsh",
                opts = {
                    zshrc = false,
                    filetypes = { "deoledit", "zsh" },
                },
            },
            {
                "L3MON4D3/LuaSnip",
                dependencies = {
                    "rafamadriz/friendly-snippets",
                    "saadparwaiz1/cmp_luasnip",
                },
                init = function()
                    require("luasnip.loaders.from_vscode").lazy_load()
                end,
                -- build = "make install_jsregexp",
            },
        },
        priority = 44,
        enabled = is_plugged,
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                sources = {
                    { name = "async_path" },
                    {
                        name = "buffer",
                        option = {
                            keyword_pattern = [[\k\+]],
                        },
                    },
                    { name = "nvim_lua" },
                    { name = "luasnip" },
                    { name = "zsh" },
                    { name = "kitty" },
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-p>"] = cmp.mapping.select_prev_item(),
                    ["<Tab>"] = cmp.mapping.select_next_item(),
                    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-u>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Tab>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<S-CR>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<S-Tab>"] = cmp.mapping.confirm({ select = false }),
                }),
                enabled = function()
                    -- disable completion in comments
                    local context = require("cmp.config.context")
                    -- keep command mode completion enabled when cursor is in a comment
                    if vim.api.nvim_get_mode().mode == "c" then
                        return true
                    else
                        return not context.in_treesitter_capture("comment") and not context.in_syntax_group("Comment")
                    end
                end,
            })
            cmp.setup.cmdline("/", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = "buffer" },
                },
            })
            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = "path" },
                }, {
                    {
                        name = "cmdline",
                        option = {
                            ignore_cmds = { "Man", "!" },
                        },
                    },
                }),
            })
            capabilities = require("cmp_nvim_lsp").default_capabilities()
        end,
    },
    {
        "mrcjkb/rustaceanvim",
        version = "^4",
        dependencies = {
            -- "mfussenegger/nvim-dap",
            {
                -- not required after vim 0.10
                "lvimuser/lsp-inlayhints.nvim",
                opts = {},
            },
        },
        enabled = is_plugged,
        ft = { "rust" },
        priority = 45,
        config = function()
            vim.g.rustaceanvim = {
                inlay_hints = {
                    highlight = "NonText",
                },
                tools = {
                    hover_actions = {
                        auto_focus = true,
                    },
                },
                server = {
                    on_attach = function(client, bufnr)
                        require("lsp-inlayhints").on_attach(client, bufnr)
                    end,
                },
            }
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "b0o/SchemaStore.nvim",
        },
        enabled = is_plugged,
        priority = 40,
        config = function()
            local lspconfig = require("lspconfig")

            lspconfig.bashls.setup({
                capabilities = capabilities,
            })
            lspconfig.pyright.setup({ capabilities = capabilities })
            lspconfig.tsserver.setup({ capabilities = capabilities })
            -- lspconfig.rust_analyzer.setup({})
            lspconfig.perlls.setup({ capabilities = capabilities })
            lspconfig.autotools_ls.setup({ capabilities = capabilities })
            lspconfig.nixd.setup({ capabilities = capabilities })
            lspconfig.jsonls.setup({
                capabilities = capabilities,

                settings = {
                    json = {
                        schemas = require("schemastore").json.schemas(),
                        provideFormatter = true,
                        validate = { enable = true },
                    },
                },
            })
            lspconfig.lua_ls.setup({
                on_init = function(client)
                    local path = client.workspace_folders[1].name
                    if
                        not vim.loop.fs_stat(path .. "/.luarc.json") and not vim.loop.fs_stat(path .. "/.luarc.jsonc")
                    then
                        client.config.settings = vim.tbl_deep_extend("force", client.config.settings, {
                            Lua = {
                                runtime = {
                                    version = "LuaJIT",
                                },
                                workspace = {
                                    checkThirdParty = false,
                                    library = {
                                        vim.env.VIMRUNTIME,
                                    },
                                },
                            },
                        })
                        client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
                    end
                    return true
                end,
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        dependencies = {
            {
                "luckasRanarison/tree-sitter-hyprlang",
                ft = { "hyprlang" },
                -- lazy = false,
            },
        },
        build = function()
            local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
            ts_update()
        end,
        main = "nvim-treesitter.configs",
        opts = {
            auto_install = true,
            highlight = {
                enable = true,
                disable = function(lang, buf)
                    local max_filesize = 100 * 1024 -- 100 KB
                    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                    if ok and stats and stats.size > max_filesize then
                        return true
                    end
                end,
            },
        },
    },
    {
        "HiPhish/rainbow-delimiters.nvim",
        lazy = false,
        main = "rainbow-delimiters.setup",
        opts = {
            highlight = delim_highlight,
        },
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        config = function()
            local hooks = require("ibl.hooks")
            hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
                for _, v in pairs(rainbow_hl_config) do
                    vim.api.nvim_set_hl(0, v.key, { fg = v.fg })
                end
            end)
            vim.g.rainbow_delimiters = { highlight = delim_highlight }
            require("ibl").setup({ scope = { highlight = delim_highlight } })

            hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
        end,
    },
    {
        "stevearc/conform.nvim",
        -- lazy = false,
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                perl = { "perltidy" },
                sh = { "shfmt" },
                bash = { "shfmt" },
                rust = { "rustfmt" },
                nix = { "nixfmt" },
                c = { "astyle" },
                cpp = { "astyle" },
                java = { "astyle" },
                -- Conform will run multiple formatters sequentially
                -- python = { "isort", "black" },
                -- Use a sub-list to run only the first available formatter
                javascript = { { "prettierd", "prettier" } },
                typescript = { { "prettierd", "prettier" } },
                jsx = { { "prettierd", "prettier" } },
                css = { { "prettierd", "prettier" } },
                less = { { "prettierd", "prettier" } },
                scss = { { "prettierd", "prettier" } },
                json = { { "prettierd", "prettier" } },
                json5 = { { "prettierd", "prettier" } },
                html = { { "prettierd", "prettier" } },
                yaml = { { "prettierd", "prettier" } },
            },
            formatters = {
                shfmt = {
                    prepend_args = { "-i", vlk_tab_width },
                },
                stylua = {
                    -- make me look like I like writing lua
                    prepend_args = { "--indent-type", "Spaces", "--indent-width", vlk_tab_width },
                },
                prettier = {
                    prepend_args = { "--tab-width", vlk_tab_width, "--no-semi" },
                },
                rustfmt = {
                    prepend_args = { "--config", "tab_spaces=" .. vlk_tab_width },
                },
                perltidy = {
                    prepend_args = { "-i=" .. vlk_tab_width },
                },
                astyle = {
                    prepend_args = { "--indent=spaces=" .. vlk_tab_width },
                },
            },
            notify_on_error = true,
            format_on_save = {
                timeout_ms = 200,
                lsp_fallback = true,
            },
        },
    },
    {
        "kevinhwang91/nvim-ufo",
        dependencies = {
            "kevinhwang91/promise-async",
        },
        enabled = is_plugged,
        opts = {
            preview = {
                win_config = {
                    -- border = {'', '─', '', '', '', '─', '', ''},
                    winhighlight = "Normal:Folded",
                    -- winblend = 0
                },
                mappings = {
                    scrollU = "<C-u>",
                    scrollD = "<C-d>",
                    jumpTop = "[",
                    jumpBot = "]",
                },
            },
            -- open_fold_hl_timeout = 150,
            fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
                local newVirtText = {}
                local suffix = (" 󰁂 %d "):format(endLnum - lnum)
                local sufWidth = vim.fn.strdisplaywidth(suffix)
                local targetWidth = width - sufWidth
                local curWidth = 0
                for _, chunk in ipairs(virtText) do
                    local chunkText = chunk[1]
                    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    if targetWidth > curWidth + chunkWidth then
                        table.insert(newVirtText, chunk)
                    else
                        chunkText = truncate(chunkText, targetWidth - curWidth)
                        local hlGroup = chunk[2]
                        table.insert(newVirtText, { chunkText, hlGroup })
                        chunkWidth = vim.fn.strdisplaywidth(chunkText)
                        -- str width returned from truncate() may less than 2nd argument, need padding
                        if curWidth + chunkWidth < targetWidth then
                            suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
                        end
                        break
                    end
                    curWidth = curWidth + chunkWidth
                end
                table.insert(newVirtText, { suffix, "MoreMsg" })
                return newVirtText
            end,
            provider_selector = function(bufnr, filetype, buftype)
                return { "treesitter", "indent" }
            end,
        },
        -- init = function()
        -- bruh
        -- end,
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "arkav/lualine-lsp-progress",
        },
        opts = {
            options = {
                icons_enabled = true,
                theme = "onedark",
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                refresh = {
                    statusline = 1000,
                    tabline = 1000,
                    winbar = 1000,
                },
            },
            globalstatus = true,
            always_divide_middle = true,
            sections = {
                lualine_a = {
                    "mode",
                },
                lualine_b = {
                    "branch",
                    "diff",
                    "diagnostics",
                },
                lualine_c = {
                    {
                        "filename",
                        file_status = true,
                        --path = 1,
                        shorting_target = 40,
                        symbols = {
                            modified = "[+]", --󰐖
                            readonly = "[-]", --󰛲
                            unnamed = "󰛲",
                            newfile = "󰐖",
                        },
                    },
                    "lsp_progress",
                },
                lualine_x = {
                    -- 'encoding',
                    -- 'fileformat',
                    -- 'filesize',
                    -- {
                    -- require("noice").api.status.message.get_hl,
                    -- cond = require("noice").api.status.message.has,
                    -- },
                    -- {
                    -- require("noice").api.status.command.get,
                    -- cond = require("noice").api.status.command.has,
                    -- },
                    -- {
                    -- require("noice").api.status.mode.get,
                    -- cond = require("noice").api.status.mode.has,
                    -- },
                    -- {
                    -- require("noice").api.status.search.get,
                    -- cond = require("noice").api.status.search.has,
                    -- },
                    {
                        "fileformat",
                        symbols = {
                            unix = "",
                            dos = "CRLF",
                            mac = "CR",
                        },
                    },
                    {
                        "filetype",
                        icon = { align = "left" },
                    },
                    {
                        require("lazy.status").updates,
                        cond = require("lazy.status").has_updates,
                        color = { fg = "#ff9e64" },
                    },
                },
                lualine_y = {
                    -- 'searchcount',
                    "progress",
                },
                lualine_z = {
                    "location",
                },
            },
        },
    },
}, {
    defaults = {
        lazy = false,
    },
    checker = {
        enabled = true,
        notify = false,
        concurrency = 1,
        -- check daily -- 60 * 60 * 24
        frequency = 86400,
    },
    change_detection = {
        enable = false,
    },
    performance = {
        rtp = {
            disabled_plugins = {
                "netrwPlugin",
                "tohtml",
            },
        },
    },
})

if nvim_tree_loaded then
    vim.api.nvim_create_autocmd({ "VimEnter" }, {
        callback = function(data)
            local no_name = data.file == "" and vim.bo[data.buf].buftype == ""
            local directory = vim.fn.isdirectory(data.file) == 1
            if not no_name and not directory then
                return
            end
            if directory then
                vim.cmd.cd(data.file)
            end
            require("nvim-tree.api").tree.open()
        end,
    })
end

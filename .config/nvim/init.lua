vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

opt = vim.opt

vlk_tab_width = 4

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

--: Be very cautious about enabling system clipboard!
opt.clipboard = ""
--opt.clipboard = 'unnamed,unnamedplus'

--vim.api.nvim_set_keymap("n", "<c-c>", '"*y :let @+=@*<CR>', {noremap=true, silent=true})
--vim.api.nvim_set_keymap("n", "<c-v>", '"+p', {noremap=true, silent=true})
--https://stackoverflow.com/a/76880300
vim.keymap.set({ "n" }, "<C-c>", '"+y$')
vim.keymap.set({ "v" }, "<C-c>", '"+y')
vim.keymap.set({ "n" }, "<C-x>", '"+d$')
vim.keymap.set({ "v" }, "<C-x>", '"+d')
vim.keymap.set({ "n" }, "<C-v>", '"+p$')
vim.keymap.set({ "v" }, "<C-v>", '"+p')

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.lazyredraw = true

-- Fixes alacritty
vim.cmd([[
    augroup change_cursor
        au!
        au ExitPre * :set guicursor=a:ver90
    augroup END
]])

vim.loader.enable()

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

require("lazy").setup({
    -- important
    "neovim/nvim-lspconfig",
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    {
        "nvim-treesitter/nvim-treesitter",
        build = function()
            local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
            ts_update()
        end,
    },
    "akinsho/toggleterm.nvim",
    "luckasRanarison/tree-sitter-hypr",
    -- UX
    "karb94/neoscroll.nvim",
    "petertriho/nvim-scrollbar",
    "lukas-reineke/indent-blankline.nvim",
    "stevearc/conform.nvim",
    "itspriddle/vim-shellcheck",
    "nvim-tree/nvim-tree.lua",
    {
        "kevinhwang91/nvim-ufo",
        dependencies = {
            "kevinhwang91/promise-async",
        },
    },
    {
        "numToStr/Comment.nvim",
        lazy = false,
    },
    "goolord/alpha-nvim",
    "m00qek/baleia.nvim",
    "olimorris/onedarkpro.nvim",
    "NvChad/nvim-colorizer.lua",
    "kevinhwang91/nvim-hlslens",
    "nvim-lualine/lualine.nvim",
    "arkav/lualine-lsp-progress",
    "nvim-telescope/telescope.nvim",
}, {
    checker = {
        --enabled = true,
    },
})

-- nvim-treesitter
require("nvim-treesitter.configs").setup({
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
})
-- so that was a fucking lie
-- vim.api.nvim_set_hl(0, "Comment", { italic = true })

local fold_handler = function(virtText, lnum, endLnum, width, truncate)
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
end

-- nvim fold
require("ufo").setup({
    fold_virt_text_handler = fold_handler,
    provider_selector = function(bufnr, filetype, buftype)
        return { "treesitter", "indent" }
    end,
})
vim.o.foldcolumn = "1"
vim.o.foldenable = true

local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.hypr = {
    install_info = {
        url = "https://github.com/luckasRanarison/tree-sitter-hypr",
        files = { "src/parser.c" },
        branch = "master",
    },
    filetype = "hypr",
}

-- nvim-lspconfig
require("lspconfig").pyright.setup({})
require("lspconfig").tsserver.setup({})
require("lspconfig").rust_analyzer.setup({})
require("lspconfig").bashls.setup({
    filetypes = { "sh", "bash" },
})
require("lspconfig").perlls.setup({})

-- conform.nvim
local prettier_table = { { "prettierd", "prettier" } }
require("conform").setup({
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
        javascript = prettier_table,
        typescript = prettier_table,
        jsx = prettier_table,
        css = prettier_table,
        less = prettier_table,
        scss = prettier_table,
        json = prettier_table,
        json5 = prettier_table,
        html = prettier_table,
        yaml = prettier_table,
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
        timeout_ms = 500,
        lsp_fallback = true,
    },
})

-- indent-blankline
local highlight = {
    "RainbowRed",
    "RainbowYellow",
    "RainbowBlue",
    "RainbowOrange",
    "RainbowGreen",
    "RainbowViolet",
    "RainbowCyan",
}
local hooks = require("ibl.hooks")
-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
    vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
    vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
    vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
    vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
    vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
    vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
end)

vim.g.rainbow_delimiters = { highlight = highlight }
require("ibl").setup({ scope = { highlight = highlight } })

hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)

-- One Dark Pro
require("onedarkpro").setup({
    theme = "onedark_vivid",
    options = {
        transparency = true,
        bold = true,
        italic = true,
        underline = false,
        undercurl = true,
    },
})
vim.cmd("colorscheme onedark_vivid")

-- alpha-nvim
require("alpha").setup(require("alpha.themes.dashboard").config)

-- toggleterm
require("toggleterm").setup({
    size = 20,
    -- open_mapping = [[<c-\>]],
    open_mapping = [[t]],
    hide_numbers = true, -- hide the number column in toggleterm buffers
    autochdir = false,
    start_in_insert = true,
    insert_mappings = false,
    terminal_mappings = false,
    direction = "float", -- 'vertical' | 'horizontal' | 'tab' | 'float'
    close_on_exit = true,
    shell = vim.o.shell,
    auto_scroll = true,
    float_opts = {
        border = "curved",
        -- width = <value>,
        -- height = <value>,
        winblend = 3,
        -- zindex = <value>,
    },
    winbar = {
        enabled = false,
        name_formatter = function(term) --  term: Terminal
            return term.name
        end,
    },
})

-- lualine
require("lualine").setup({
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
                path = 1,
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
    -- extensions = {
    --     'toggleterm',
    -- },
})
opt.showmode = true

require("hlslens").setup()

-- nvim-tree
require("nvim-tree").setup()
local function open_nvim_tree(data)
    local no_name = data.file == "" and vim.bo[data.buf].buftype == ""
    local directory = vim.fn.isdirectory(data.file) == 1
    if not no_name and not directory then
        return
    end
    if directory then
        vim.cmd.cd(data.file)
    end
    require("nvim-tree.api").tree.open()
end
vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })

-- neoscroll
require("neoscroll").setup({ easing_function = "quadratic" })

-- nvim scrollbar
require("scrollbar").setup()

-- colorizer
require("colorizer").setup({
    filetypes = { "*" },
    user_default_options = {
        RRGGBBAA = true,
        mode = "background",
    },
})

-- comment
require("Comment").setup({
    padding = true,
    sticky = true,
    toggler = { line = "," },
})
--vim.keymap.set({ "n" }, ",", "gcc")

-- telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})

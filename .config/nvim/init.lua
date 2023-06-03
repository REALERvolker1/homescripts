
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

opt = vim.opt
map = vim.api.nvim_set_keymap

opt.tabstop = 4
opt.expandtab = true
opt.shiftwidth = 0
opt.shiftround = true
opt.autoindent = true
opt.smartindent = true

opt.wrap = true
--opt.scrolloff = 10
opt.termguicolors = true
opt.cursorline = false
opt.undofile = true

--[[
opt.number = true
opt.relativenumber = true
opt.numberwidth = 2
--]]
--opt.showbreak = "↪ "

opt.mouse = null
opt.listchars = 'trail:·,nbsp:◇,tab:→ ,extends:▸,precedes:◂'
opt.list = true
--vim.opt.listchars:append "space:⋅"
--vim.opt.listchars:append "eol:↴"
opt.foldmethod = 'marker'

--: Be very cautious about enabling system clipboard!
--opt.clipboard = 'unnamedplus'

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.lazyredraw = true

-- Fixing terminals {{{

-- Fixes alacritty
vim.cmd
[[
    augroup change_cursor
        au!
        au ExitPre * :set guicursor=a:ver90
    augroup END
]]

separator_type=os.getenv("ICON_TYPE")

if (separator_type == "dashline") then
    mysep = { left = '', right = '' }
    mycum = { left = '', right = '' } --  
elseif (separator_type == "powerline") then
    mysep = { left = '', right = '' }
    mycum = { left = '', right = '' }
else
    mysep = { left = ']', right = '[' }
    mycum = { left = '/', right =  '\\'}
end

-- }}}

vim.cmd [[packadd packer.nvim]]

vim.cmd [[packadd packer.nvim]]

require('packer').startup(function(use)
    -- important
    use 'wbthomason/packer.nvim'
    use 'lewis6991/impatient.nvim'
    use 'neovim/nvim-lspconfig'
    use 'nvim-lua/plenary.nvim'
    use {
        'nvim-treesitter/nvim-treesitter',
        run = function()
        local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
        ts_update()
        end,
    }
    -- UX
    use 'karb94/neoscroll.nvim'
    use 'lukas-reineke/indent-blankline.nvim'
    use 'mhartington/formatter.nvim'
    use {
        'nvim-tree/nvim-tree.lua',
        requires = { 'nvim-tree/nvim-web-devicons' },
    }
    use {
        'goolord/alpha-nvim',
        requires = { 'nvim-tree/nvim-web-devicons' },
    }
    use 'm00qek/baleia.nvim'

    -- visuals
    use 'olimorris/onedarkpro.nvim'
    use 'kwshi/nvim-colorizer.lua'
    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'nvim-tree/nvim-web-devicons', opt = true }
    }
    use {
        'nvim-telescope/telescope.nvim',
        requires = { {'nvim-lua/plenary.nvim'} }
    }
end)

-- disabled {{{
--[[
    use 'ray-x/cmp-treesitter'
    use 'hrsh7th/cmp-nvim-lsp'
    use 'hrsh7th/cmp-buffer'
    use 'hrsh7th/cmp-path'
    use 'hrsh7th/cmp-cmdline'
    use 'hrsh7th/nvim-cmp'
    use 'christoomey/vim-tmux-navigator'

    use "norcalli/nvim-colorizer.lua"

    use {
        'kdheepak/tabline.nvim',
        config = function()
            require'tabline'.setup {
                enable = true,
                options = {
                    --modified_icon = "+ "
                }
            }
            vim.cmd[[
                set guioptions-=e
                set sessionoptions+=tabpages,globals
                ] ]
        end,
        requires = { { 'hoob3rt/lualine.nvim', opt=true }, {'nvim-tree/nvim-web-devicons', opt
 = true} }
    }
    use {
        'samodostal/image.nvim',
        requires = {
            'nvim-lua/plenary.nvim'
        },
    }
    --use {'edluffy/hologram.nvim'}
    --use 'elkowar/yuck.vim'
    --use 'ryanoasis/vim-devicons'
    --use 'waycrate/swhkd-vim'
--]]
-- }}}

-- check out https://github.com/folke/lazy.nvim

--git clone --depth 1 https://github.com/wbthomason/packer.nvim\
-- ~/.local/share/nvim/site/pack/packer/start/packer.nvim

-- impatient.nvim
require('impatient')

-- nvim-lspconfig
require('lspconfig')['pyright'].setup{
    on_attach = on_attach,
    capabilities = capabilities,
    flags = lsp_flags,
}
require('lspconfig')['tsserver'].setup{
    on_attach = on_attach,
    capabilities = capabilities,
    flags = lsp_flags,
}
require('lspconfig')['rust_analyzer'].setup{
    on_attach = on_attach,
    capabilities = capabilities,
    flags = lsp_flags,
    -- Server-specific settings...
    settings = {
      ["rust-analyzer"] = {}
    }
}

-- nvim-treesitter
require('nvim-treesitter.configs').setup {
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
    }
}

-- indent-blankline
vim.cmd [[highlight IndentBlanklineIndent1 guibg=#282c34 gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent2 guibg=#3e4451 gui=nocombine]]

require("indent_blankline").setup {
    char = "",
    char_highlight_list = {
        "IndentBlanklineIndent1",
        "IndentBlanklineIndent2",
    },
    space_char_highlight_list = {
        "IndentBlanklineIndent1",
        "IndentBlanklineIndent2",
    },
    space_char_blankline = " ",
    show_trailing_blankline_indent = true,
}

-- formatter.nvim
local formatter_util = require "formatter.util"
local formatter_defaults = require "formatter.defaults"
require("formatter").setup {
    logging = true,
    log_level = vim.log.levels.WARN,
    filetype = {
        ["*"] = {
            formatter_util.withl(formatter_defaults.sed, "[ 	]*$")
        },
    }
}

-- One Dark Pro
require("onedarkpro").setup({
    theme = "onedark_vivid",
    --[[colors = {
        bg = "#FFFFFF",
    },--]]
    options = {
        transparency = true,
        bold = true,
        italic = true,
        underline = false,
        undercurl = true
    }
})
vim.cmd("colorscheme onedark_vivid")

-- alpha-nvim
require('alpha').setup(require('alpha.themes.dashboard').config)

-- lualine
require('lualine').setup {
    options = {
        theme = 'onedark',
        --theme = 'material',
        component_separators = mycum,
        section_separators = mysep,
    }
}

-- nvim-tree
require("nvim-tree").setup()
local function open_nvim_tree(data)
    local no_name = data.file == "" and vim.bo[data.buf].buftype == ""

    -- buffer is a directory
    local directory = vim.fn.isdirectory(data.file) == 1

    if not no_name and not directory then
        return
    end

    -- change to the directory
    if directory then
        vim.cmd.cd(data.file)
    end

    -- open the tree
    require("nvim-tree.api").tree.open()
end
vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })

-- neoscroll
require('neoscroll').setup({ easing_function = "quadratic" })

-- colorizer
require'colorizer'.setup(nil, {
    RRGGBBAA = true;
})

-- telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
-- disabled {{{
--[[

local cmp = require('cmp')
cmp.setup({
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),·
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
    }, {
        { name = 'buffer' },
    }, {
        { name = 'path' },
    }, {
        { name = 'cmdline' },
    }, {
        { name = 'treesitter' },
    })
})

require('image').setup {
    render = {
        min_padding = 5,
        show_label = true,
        use_dither = true,
        foreground_color = true,
        background_color = true
    },
    events = {
        update_on_nvim_resize = true,
    },
}

require('hologram').setup{
    auto_display = true
}


--]]

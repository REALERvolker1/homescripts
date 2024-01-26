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
opt.foldcolumn = "1"
-- opt.foldlevel = 99
opt.foldenable = true
--opt.foldmethod = "syntax"

--https://stackoverflow.com/a/76880300
vim.keymap.set("n", "<C-c>", '"+y$')
vim.keymap.set("v", "<C-c>", '"+y')
vim.keymap.set("n", "<C-x>", '"+d$')
vim.keymap.set("v", "<C-x>", '"+d')
vim.keymap.set("n", "<C-v>", '"+p$')
vim.keymap.set("v", "<C-v>", '"+p')

--: Be very cautious about enabling system clipboard!
--opt.clipboard = 'unnamed,unnamedplus'
opt.clipboard = ""

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.lazyredraw = true

opt.showmode = true

-- Fixes alacritty
vim.cmd([[
    augroup change_cursor
        au!
        au ExitPre * :set guicursor=a:ver90
    augroup END
]])

vim.loader.enable()

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
for i, v in pairs(rainbow_hl_config) do
	table.insert(delim_highlight, v.key)
end

local nvim_tree_loaded = false

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
	{
		"nvim-lua/plenary.nvim",
		lazy = true,
	},
	{
		"nvim-tree/nvim-web-devicons",
		lazy = true,
	},
	{
		"numToStr/Comment.nvim",
		lazy = false,
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
		"m00qek/baleia.nvim",
		lazy = true,
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
			-- vim.cmd("colorscheme onedark")
			vim.cmd("colorscheme onedark_vivid")
		end,
	},
	{
		"NvChad/nvim-colorizer.lua",
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
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},
	{
		"kevinhwang91/nvim-hlslens",
		opts = {
			-- clear highlight on cursor move
			calm_down = false,
			nearest_only = true,
		},
	},
	{
		"karb94/neoscroll.nvim",
		lazy = false,
		opts = {
			easing_function = "quadratic",
		},
	},
	{
		"petertriho/nvim-scrollbar",
		lazy = false,
		config = true,
	},
	{
		"nvim-telescope/telescope.nvim",
		lazy = true,
		init = function()
			-- default leader: \
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
			vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
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
		"neovim/nvim-lspconfig",
		-- dependencies = {
		--     "itspriddle/vim-shellcheck",
		-- },
		config = function()
			local lspconfig = require("lspconfig")

			lspconfig.pyright.setup({})
			lspconfig.tsserver.setup({})
			lspconfig.rust_analyzer.setup({})
			lspconfig.bashls.setup({})
			lspconfig.perlls.setup({})
			lspconfig.autotools_ls.setup({})
			lspconfig.jsonls.setup({
				settings = {
					json = {
						-- schemas = require('schemastore').json.schemas(),
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
									-- Tell the language server which version of Lua you're using
									-- (most likely LuaJIT in the case of Neovim)
									version = "LuaJIT",
								},
								-- Make the server aware of Neovim runtime files
								workspace = {
									checkThirdParty = false,
									library = {
										vim.env.VIMRUNTIME,
										-- "${3rd}/luv/library"
										-- "${3rd}/busted/library",
									},
									-- or pull in all of 'runtimepath'. NOTE: this is a lot slower
									-- library = vim.api.nvim_get_runtime_file("", true)
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
				lazy = false,
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
				for i, v in pairs(rainbow_hl_config) do
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
		init = function()
			-- bruh
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
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
	-- profiling = {
	-- loader = true,
	-- require = true,
	-- }
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

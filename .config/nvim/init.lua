vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local opt = vim.opt

local vlk_tab_width = 4
local vlk_expand_tab = false

opt.tabstop = vlk_tab_width
opt.expandtab = vlk_expand_tab
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
	pattern = { [".*/hypr/.*%.conf"] = "hyprlang" },
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
	fh:close()
	if content and content:lower() == "discharging" then
		is_plugged = false
	end
end

-- local vlk_c_formatter = { "astyle" }
local vlk_c_formatter = { "clang-format" }
local vlk_js_formatter = {
	"biome",
	"prettierd",
	"prettier",
	stop_after_first = true,
}

local vlk_web_formatter = { "prettierd", "prettier", stop_after_first = true }

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	local output = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		error("Failed to clone lazy.nvim: " .. output)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	{
		"numToStr/Comment.nvim",
		-- lazy = false,
		event = "BufEnter",
		opts = {
			padding = true,
			sticky = true,
			toggler = { line = ",", block = "<C-,>" },
		},
	},
	{
		"goolord/alpha-nvim",
		config = function()
			require("alpha").setup(require("alpha.themes.dashboard").config)
		end,
	},
	--[[{
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
    },]]
	-- {
	-- "windwp/nvim-autopairs",
	-- event = "InsertEnter",
	-- config = true,
	-- },
	{
		"olimorris/onedarkpro.nvim",
		lazy = false,
		priority = 1000,
		opts = {
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
		config = function(_, opts)
			require("onedarkpro").setup(opts)
			vim.cmd("colorscheme onedark_vivid")
		end,
	},
	--[[{
        "mikesmithgh/kitty-scrollback.nvim",
        enabled = is_kitty,
        lazy = true,
        cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
        event = { "User KittyScrollbackLaunch" },
        config = function()
            require("kitty-scrollback").setup()
        end,
    },]]
	{
		"catgoose/nvim-colorizer.lua",
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
		"m00qek/baleia.nvim",
		version = "*",
		cmd = { "BaleiaColorize" },
		config = function()
			local baleia = require("baleia").setup({})

			-- Command to colorize the current buffer
			vim.api.nvim_create_user_command("BaleiaColorize", function()
				baleia.once(vim.api.nvim_get_current_buf())
			end, { bang = true })
		end,
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
			easing = "quadratic",
			duration_multiplier = 0.75,
		},
	},
	--[[{
        "petertriho/nvim-scrollbar",
        event = "BufEnter",
        config = true,
    }, ]]
	{
		"dstein64/nvim-scrollview",
		event = "BufEnter",
		opts = {
			hide_on_text_intersect = true,
		},
	},
	--[[{
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
    }, ]]
	{
		"brenton-leighton/multiple-cursors.nvim",
		version = "*",
		opts = {},
		keys = {
			{
				"<M-Down>",
				"<Cmd>MultipleCursorsAddDown<CR>",
				mode = { "n", "i" },
				desc = "Add multiple cursors down",
			},
			{ "<M-j>", "<Cmd>MultipleCursorsAddDown<CR>", desc = "Add multiple cursors down" },
			{
				"<M-Up>",
				"<Cmd>MultipleCursorsAddUp<CR>",
				mode = { "n", "i" },
				desc = "Add multiple cursors up",
			},
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
		cmd = "Telescope",
		keys = { "<leader>fF", "<leader>ff", "<leader>fb", "<leader>fk", "<leader>fc", "<leader>fp", "<leader>fh" },
		config = function()
			require("telescope").setup({})
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
				-- Without remote control, every availability check emits a warning.
				enabled = is_kitty and (vim.env.KITTY_WINDOW_ID or "") ~= "" and (vim.env.KITTY_LISTEN_ON or "") ~= "",
				config = function()
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
				config = function()
					require("luasnip.loaders.from_vscode").lazy_load()
				end,
				-- build = "make install_jsregexp",
			},
		},
		priority = 44,
		cond = is_plugged,
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				sources = {
					{ name = "nvim_lsp" },
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
					{ name = "async_path" },
				}, {
					{
						name = "cmdline",
						option = {
							ignore_cmds = { "Man", "!" },
						},
					},
				}),
			})
		end,
	},
	{
		"mrcjkb/rustaceanvim",
		version = "^9",
		dependencies = {
			-- "mfussenegger/nvim-dap",
		},
		cond = is_plugged,
		lazy = false,
		init = function()
			vim.g.rustaceanvim = {
				tools = {
					float_win_config = {
						auto_focus = true,
					},
				},
				-- server = {
				-- on_attach = function(client, bufnr)
				-- require("lsp-inlayhints").on_attach(client, bufnr)
				-- end,
				-- },
			}
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"b0o/SchemaStore.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		cond = is_plugged,
		priority = 40,
		config = function()
			-- vim.lsp.config.rust_analyzer.setup({}) -- causes conflicts with rustaceanvim
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			vim.lsp.config("*", { capabilities = capabilities })
			vim.lsp.config("jsonls", {
				settings = {
					json = {
						schemas = require("schemastore").json.schemas(),
						provideFormatter = true,
						validate = { enable = true },
					},
				},
			})
			vim.lsp.config("lua_ls", {
				---@param client vim.lsp.Client
				on_init = function(client)
					local workspace = client.workspace_folders and client.workspace_folders[1]
					local path = workspace and workspace.name or vim.fn.getcwd()
					if not vim.uv.fs_stat(path .. "/.luarc.json") and not vim.uv.fs_stat(path .. "/.luarc.jsonc") then
						client.settings = vim.tbl_deep_extend("force", client.settings, {
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
						client:notify("workspace/didChangeConfiguration", { settings = client.settings })
					end
					return true
				end,
			})
			vim.lsp.enable({ "bashls", "pyright", "ts_ls", "perlls", "autotools_ls", "nixd", "jsonls", "lua_ls" })
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		-- main = "nvim-treesitter.configs",
		opts = {}, -- main uses native highlighting; see the FileType handler below.
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
		-- This will provide type hinting with LuaLS
		---@module "conform"
		---@type conform.setupOpts
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				perl = { "perltidy" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				rust = { "rustfmt" },
				nix = { "nixfmt" },
				c = vlk_c_formatter,
				cpp = vlk_c_formatter,
				go = { "gofmt" },
				java = { "astyle" },
				markdown = vlk_web_formatter,
				awk = { "gawk" },
				-- Conform will run multiple formatters sequentially
				-- python = { "isort", "black" },
				-- Use stop_after_first to run only the first available formatter
				javascript = vlk_js_formatter,
				typescript = vlk_js_formatter,
				javascriptreact = vlk_js_formatter,
				typescriptreact = vlk_js_formatter,
				css = vlk_js_formatter,
				less = vlk_web_formatter,
				scss = vlk_web_formatter,
				json = vlk_js_formatter,
				json5 = vlk_js_formatter,
				html = vlk_web_formatter,
				yaml = { "yamlfmt" },
				python = function(bufnr)
					if require("conform").get_formatter_info("ruff_format", bufnr).available then
						return { "ruff_format" }
					else
						return { "ufmt" }
					end
				end,
				["_"] = { "trim_whitespace" },
			},
			formatters = {
				-- Conform’s Biome defaults respect biome.json and buffer indentation.
				shfmt = {
					prepend_args = { "-i", vlk_expand_tab and vlk_tab_width or 0 },
				},
				stylua = {
					-- make me look like I like writing lua
					prepend_args = {
						"--indent-type",
						vlk_expand_tab and "Spaces" or "Tabs",
						"--indent-width",
						vlk_tab_width,
					},
				},
				prettierd = {
					append_args = { "--tab-width=" .. vlk_tab_width, "--use-tabs=" .. tostring(not vlk_expand_tab) },
				},
				prettier = {
					prepend_args = {
						"--tab-width",
						vlk_tab_width,
						"--no-semi",
						vlk_expand_tab and "--no-use-tabs" or "--use-tabs",
					},
				},
				rustfmt = {
					prepend_args = {
						"--config",
						"hard_tabs=" .. tostring(not vlk_expand_tab) .. ",tab_spaces=" .. vlk_tab_width,
					},
				},
				perltidy = {
					prepend_args = vlk_expand_tab and { "-i=" .. vlk_tab_width }
						or { "-i=" .. vlk_tab_width, "-et=" .. vlk_tab_width },
				},
				astyle = {
					prepend_args = {
						vlk_expand_tab and "--indent=spaces=" .. vlk_tab_width
							or "--indent=force-tab=" .. vlk_tab_width,
					},
				},
				["clang-format"] = {
					prepend_args = {
						"--style={BasedOnStyle: InheritParentConfig, UseTab: "
							.. (vlk_expand_tab and "Never" or "ForIndentation")
							.. ", IndentWidth: "
							.. vlk_tab_width
							.. ", TabWidth: "
							.. vlk_tab_width
							.. "}",
					},
				},
				injected = {
					-- Set to true to ignore errors
					ignore_errors = true,
					-- Map of treesitter language to filetype
					lang_to_ft = {
						bash = "sh",
					},
					-- Map of treesitter language to file extension
					-- A temporary file name with this extension will be generated during formatting
					-- because some formatters care about the filename.
					lang_to_ext = {
						bash = "sh",
						c_sharp = "cs",
						elixir = "exs",
						javascript = "js",
						julia = "jl",
						latex = "tex",
						markdown = "md",
						python = "py",
						ruby = "rb",
						rust = "rs",
						teal = "tl",
						typescript = "ts",
					},
				},
			},
			notify_on_error = false,
			notify_no_formatters = false,
			format_on_save = {
				timeout_ms = 500,
				lsp_format = "fallback",
				quiet = true,
			},
		},
	},
	{
		"kevinhwang91/nvim-ufo",
		dependencies = {
			"kevinhwang91/promise-async",
		},
		cond = is_plugged,
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
		},
		opts = {
			options = {
				globalstatus = true,
				always_divide_middle = true,
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
					"lsp_status",
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
		enabled = false,
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

-- Only clear problematic markdown injection queries — do NOT start treesitter here
-- query.set takes a language and query name, not a buffer; an empty query disables injections.
vim.treesitter.query.set("markdown", "injections", "")
vim.treesitter.query.set("markdown_inline", "injections", "")

local max_filesize = 102400 -- 100 KB

---@param buf integer
---@return string? lang
local function treesitter_language(buf)
	if not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].buftype ~= "" then
		return
	end
	local ft = vim.bo[buf].filetype
	if ft == "" or ft == "markdown" or ft == "markdown_inline" then
		return
	end
	if vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf)) > max_filesize then
		return
	end
	return vim.treesitter.language.get_lang(ft)
end

local installing = {} ---@type table<string, boolean>

-- Safe fallback: attempt to start treesitter for non-empty, non-markdown filetypes
-- FileType also handles new files and :setfiletype, unlike BufReadPost.
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("VlkTreesitter", { clear = true }),
	---@param ev vim.api.keyset.create_autocmd.callback_args
	callback = function(ev)
		local lang = treesitter_language(ev.buf)
		if not lang then
			-- Neovim 0.12 starts Markdown highlighting in its own ftplugin.
			vim.treesitter.stop(ev.buf)
			return
		end
		if pcall(vim.treesitter.start, ev.buf, lang) then
			return
		end
		local ts = require("nvim-treesitter")
		if installing[lang] or not vim.tbl_contains(ts.get_available(), lang) then
			return
		end
		installing[lang] = true
		---@param err string?
		---@param installed boolean?
		local function on_install(err, installed)
			vim.schedule(function()
				installing[lang] = nil
				if err or not installed then
					vim.notify("Tree-sitter could not install " .. lang .. "; see :messages", vim.log.levels.WARN)
					return
				end
				-- A parser build may finish after the original buffer has changed or closed.
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if treesitter_language(buf) == lang then
						local ok, start_err = pcall(vim.treesitter.start, buf, lang)
						if not ok then
							vim.notify(tostring(start_err), vim.log.levels.WARN)
						end
					end
				end
			end)
		end
		-- Rebuild on failure: leftover queries can otherwise make a missing parser look installed.
		ts.install({ lang }, { force = true }):await(on_install)
	end,
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

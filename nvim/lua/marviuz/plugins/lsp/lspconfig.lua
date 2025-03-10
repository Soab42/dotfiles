return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		-- import lspconfig plugin
		local lspconfig = require("lspconfig")
		local util = require("lspconfig.util")

		-- import mason_lspconfig plugin
		local mason_lspconfig = require("mason-lspconfig")

		-- import cmp-nvim-lsp plugin
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local map = require("marviuz.utils.map")

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local opts = { buffer = ev.buf, silent = true }

				-- set keybinds
				opts.desc = "Show LSP references"
				map("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

				opts.desc = "Go to declaration"
				map("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

				opts.desc = "Show LSP definitions"
				map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

				opts.desc = "Show LSP implementations"
				map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

				opts.desc = "Show LSP type definitions"
				map("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

				-- Use LSP saga code action instead
				-- opts.desc = "See available code actions"
				-- map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

				-- Use lspsaga to refactor variables
				-- opts.desc = "Smart rename"
				-- map("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

				opts.desc = "Show buffer diagnostics"
				map("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

				-- Remaped to be used in `deleted to void register`
				-- opts.desc = "Show line diagnostics"
				-- map("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

				opts.desc = "Go to previous diagnostic"
				map("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

				opts.desc = "Go to next diagnostic"
				map("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

				-- Use Lspsaga to hover
				-- opts.desc = "Show documentation for what is under cursor"
				-- map("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

				opts.desc = "Restart LSP"
				map("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
			end,
		})

		-- used to enable autocompletion (assign to every lsp server config)
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Change the Diagnostic symbols in the sign column (gutter)
		-- (not in youtube nvim video)
		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		mason_lspconfig.setup_handlers({
			-- default handler for installed servers
			function(server_name)
				lspconfig[server_name].setup({
					capabilities = capabilities,
				})
			end,
			["eslint"] = function()
				lspconfig["eslint"].setup({
					capabilities = capabilities,
					on_new_config = function(config, new_root_dir)
						config.settings.workspaceFolder = {
							uri = vim.uri_from_fname(new_root_dir),
							name = vim.fn.fnamemodify(new_root_dir, ":t"),
						}
					end,
				})

				map({ "n", "v" }, "<leader>me", ":EslintFixAll<cr>", { desc = "Run :EslintFixAll" })
			end,
			["ts_ls"] = function()
				local function organize_imports()
					local params = {
						command = "_typescript.organizeImports",
						arguments = { vim.api.nvim_buf_get_name(0) },
						title = "",
					}
					vim.lsp.buf.execute_command(params)
				end

				lspconfig["ts_ls"].setup({
					capabilities = capabilities,
					commands = {
						OrganizeImports = {
							organize_imports,
							description = "Organize Imports",
						},
					},
					filetypes = {
						"typescriptreact",
						"javascriptreact",
						"typescript",
						"javascript",
						"markdown.mdx",
					},
				})

				map("n", "<leader>oi", "<cmd>OrganizeImports<CR>", { desc = "Organize imports" })
			end,
			["tailwindcss"] = function()
				lspconfig["tailwindcss"].setup({
					capabilities = capabilities,
					settings = {
						tailwindCSS = {
							experimental = {
								classRegex = {
									{ "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
									{ "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
								},
							},
						},
					},
				})
			end,
			["mdx_analyzer"] = function()
				local function get_typescript_server_path(_root_dir)
					-- local project_root = util.find_node_modules_ancestor(root_dir)
					local project_root = vim.fs.dirname(vim.fs.find("node_modules", { path = "./", upward = true })[1])
					-- return project_root and (util.path.join(project_root, "node_modules", "typescript", "lib")) or ""
					return project_root and (table.concat({ "path1", "path2" })) or ""
				end
				lspconfig["mdx_analyzer"].setup({
					capabilities = capabilities,
					filetypes = { "markdown.mdx", "mdx" },
					init_options = {
						typescript = {},
					},
					on_new_config = function(new_config, new_root_dir)
						if
							vim.tbl_get(new_config.init_options, "typescript")
							and not new_config.init_options.typescript.sdk
						then
							new_config.init_options.typescript.tsdk = get_typescript_server_path(new_root_dir)
						end
					end,
				})
			end,
			["emmet_ls"] = function()
				-- configure emmet language server
				lspconfig["emmet_ls"].setup({
					capabilities = capabilities,
					filetypes = {
						"html",
						"typescriptreact",
						"javascriptreact",
						"css",
						"sass",
						"scss",
						"less",
						"svelte",
					},
				})
			end,
			["lua_ls"] = function()
				-- configure lua server (with special settings)
				lspconfig["lua_ls"].setup({
					capabilities = capabilities,
					settings = {
						Lua = {
							-- make the language server recognize "vim" global
							diagnostics = {
								globals = { "vim" },
							},
							completion = {
								callSnippet = "Replace",
							},
						},
					},
				})
			end,
		})

		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
			border = "rounded",
		})
	end,
}

return {
	{
		"neovim/nvim-lspconfig",
		---@param opts PluginLspOpts
		opts = function(_, opts)
			opts.format = vim.tbl_deep_extend("force", opts.format or {}, { timeout_ms = 5000 })

			opts.servers = opts.servers or {}
			opts.servers["*"] = opts.servers["*"] or {}
			opts.servers["*"].keys = vim.list_extend(opts.servers["*"].keys or {}, {
                -- stylua: ignore
                { "<c-s-k>", function() return vim.lsp.buf.signature_help() end, mode = "i", desc = "Signature Help", has = "signatureHelp" },
			})

			require("lspconfig.ui.windows").default_options.border = "rounded"
		end,
	},

	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				python = { "ruff_fix", "ruff_format" },
				rust = { "rustfmt" },
				vue = { "biome" },
				typescript = { "biome" },
				typescriptreact = { "biome" },
				javascript = { "biome" },
				javascriptreact = { "biome" },
			},
		},
	},
}

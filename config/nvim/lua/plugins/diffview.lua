return {
	"sindrets/diffview.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	keys = {
		{ "<leader>dv", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
		{ "<leader>dx", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
		{ "<leader>dh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
	},
}

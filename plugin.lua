return {
	"cellexec/tasks.nvim",
	config = function()
		-- Map <leader>t to trigger task picker
		vim.api.nvim_set_keymap("n", "<leader>t", ":lua require('tasks').open_tasks()<CR>",
			{ noremap = true, silent = true })
	end,
}

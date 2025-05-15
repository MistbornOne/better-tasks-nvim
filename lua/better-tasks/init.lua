local M = {}

M.options = {
	categories = { "Coding", "Notes", "Life", "Work" },
}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.options, opts or {})
	require("better-tasks.commands").setup_keymaps()
end

return M

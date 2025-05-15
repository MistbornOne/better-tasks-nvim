local M = {}

local storage = require("better-tasks.storage")

M.options = {
	categories = { "Coding", "Notes", "Life", "Work" },
}

function M.setup(opts)
	opts = opts or {}

	local saved = storage.load() or {}

	local merged = vim.deepcopy(M.options.categories)
	for _, cat in ipairs(saved) do
		if not vim.tbl_contains(merged, cat) then
			table.insert(merged, cat)
		end
	end
	for _, cat in ipairs(opts.categories or {}) do
		if not vim.tbl_contains(merged, cat) then
			table.insert(merged, cat)
		end
	end

	M.options.categories = merged
	require("better-tasks.commands").setup_keymaps()
end

return M

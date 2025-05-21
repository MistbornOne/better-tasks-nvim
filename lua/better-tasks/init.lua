local M = {}

local storage = require("better-tasks.storage")

M.options = {
	categories = { "Coding", "Notes", "Life", "Work" },
	statuses = { "TODO", "In Progress", "Stalled", "Cancel", "Done" },
	master_file = nil,
	archive_file = nil,
}

function M.setup(opts)
	opts = opts or {}

	if opts.master_file then
		M.options.master_file = opts.master_file
	end

	if opts.archive_file then
		M.options.archive_file = opts.archive_file
	end

	-- Categories
	local saved_categories = storage.load_categories() or {}

	local merged_categories = vim.deepcopy(M.options.categories)
	for _, cat in ipairs(saved_categories) do
		if not vim.tbl_contains(merged_categories, cat) then
			table.insert(merged_categories, cat)
		end
	end
	for _, cat in ipairs(opts.categories or {}) do
		if not vim.tbl_contains(merged_categories, cat) then
			table.insert(merged_categories, cat)
		end
	end

	M.options.categories = merged_categories

	-- Statuses
	local saved_statuses = storage.load_statuses() or {}
	local merged_statuses = vim.deepcopy(M.options.statuses)

	for _, s in ipairs(saved_statuses) do
		if not vim.tbl_contains(merged_statuses, s) then
			table.insert(merged_statuses, s)
		end
	end
	for _, s in ipairs(opts.statuses or {}) do
		if not vim.tbl_contains(merged_statuses, s) then
			table.insert(merged_statuses, s)
		end
	end

	M.options.statuses = merged_statuses

	require("better-tasks.commands").setup_keymaps()
end

return M

local core = require("better-tasks.core")
--print(vim.inspect(core))

local M = {}

function M.setup_keymaps()
	vim.keymap.set("n", "<leader>tn", core.insert_task, { desc = "Insert New Task" })
	vim.keymap.set("n", "<leader>td", core.mark_done, { desc = "Mark Task as Done" })
	vim.keymap.set(
		"n",
		"<leader>tt",
		core.set_status_prompt,
		{ desc = "Pick New Status (pop-up)", nowait = true, silent = true }
	)

	-- Commands
	vim.api.nvim_create_user_command("BetterTasksEditCategories", core.edit_categories, {})
	vim.api.nvim_create_user_command("BetterTasksEditStatuses", core.edit_statuses, {})
	vim.api.nvim_create_user_command("BTSync", core.sync_today_tasks, {})
	vim.api.nvim_create_user_command("BTViewMaster", function()
		vim.cmd("edit " .. vim.fn.stdpath("data") .. "/better-tasks/master_tasks.md")
	end, {})

	vim.api.nvim_create_user_command("BTViewArchive", function()
		vim.cmd("edit " .. vim.fn.stdpath("data") .. "/better-tasks/task_archive.md")
	end, {})
end

return M

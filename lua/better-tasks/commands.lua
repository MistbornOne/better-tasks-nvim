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

	-- Edit Categories and Statuses
	vim.api.nvim_create_user_command("BetterTasksEditCategories", core.edit_categories, {})
	vim.api.nvim_create_user_command("BetterTasksEditStatuses", core.edit_statuses, {})

	-- Sync to Archive and Master
	vim.api.nvim_create_user_command("BTSync", core.sync_today_tasks, {})

	-- View Master In Pop Up Buffer Window
	vim.api.nvim_create_user_command("BTMaster", function()
		local path = vim.fn.stdpath("data") .. "/better-tasks/master_tasks.md"
		core.open_markdown_popup(path, "Master Tasks")
	end, {})

	-- Viwe Archive in Pop Up Buffer Window
	vim.api.nvim_create_user_command("BTArchive", function()
		local path = vim.fn.stdpath("data") .. "/better-tasks/task_archive.md"
		core.open_markdown_popup(path, "Task Archive")
	end, {})

	-- Go to Master in current buffer
	vim.api.nvim_create_user_command("BTViewMaster", function()
		vim.cmd("edit " .. vim.fn.stdpath("data") .. "/better-tasks/master_tasks.md")
	end, {})

	-- Go to Archive in current buffer
	vim.api.nvim_create_user_command("BTViewArchive", function()
		vim.cmd("edit " .. vim.fn.stdpath("data") .. "/better-tasks/task_archive.md")
	end, {})
end

return M

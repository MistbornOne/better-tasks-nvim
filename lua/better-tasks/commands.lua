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
	--vim.api.nvim_create_user_command("BetterTasksToday", core.show_today_tasks, {})
	--vim.api.nvim_create_user_command("BetterTasksEditCategories", core.edit_categories, {})
end

return M

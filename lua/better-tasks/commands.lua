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
end

return M

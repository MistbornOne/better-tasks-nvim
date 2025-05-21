local core = require("better-tasks.core")
local sort = require("better-tasks.sort")
local formatter = require("better-tasks.format")

local M = {}

--=============
-- Keymaps
--============

function M.setup_keymaps()
	vim.keymap.set("n", "<leader>tn", core.insert_task, { desc = "Insert New Task" })
	vim.keymap.set("n", "<leader>td", core.mark_done, { desc = "Mark Task as Done" })
	vim.keymap.set(
		"n",
		"<leader>tt",
		core.set_status_prompt,
		{ desc = "Pick New Status (pop-up)", nowait = true, silent = true }
	)
	vim.keymap.set("n", "<leader>tm", core.view_master_popup, { desc = "Master Task Popup" })
	vim.keymap.set("n", "<leader>ta", core.view_archive_popup, { desc = "Archive Popup" })
	vim.keymap.set(
		"n",
		"<leader>tw",
		core.set_due_date_prompt,
		{ desc = "Pick New Date", nowait = true, silent = true }
	)

	-- Sorting Keymaps
	vim.keymap.set("n", "<leader>ss", function()
		sort.sort_buffer_tasks({ sort_open_by = "status" })
	end, { desc = "Sort Tasks: Done first, open by Status" })
	vim.keymap.set("n", "<leader>sd", function()
		sort.sort_buffer_tasks({ sort_open_by = "date" })
	end, { desc = "Sort Tasks: Done first, open by Date" })

	-- Format Keymap
	vim.keymap.set("n", "<leader>fmt", formatter.format_all_tasks, { desc = "Format All Tasks" })
	vim.keymap.set("n", "<leader>fms", formatter.show_full_task_under_cursor, { desc = "Show full task under cursor" })

	--==========
	-- Commands
	--==========

	-- Edit Categories and Statuses and Date
	vim.api.nvim_create_user_command("BTEditCategories", core.edit_categories, {})
	vim.api.nvim_create_user_command("BTEditStatuses", core.edit_statuses, {})

	vim.api.nvim_create_user_command("BTDate", core.set_due_date_prompt, {})

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

	-- Format Tasks in Buffer
	vim.api.nvim_create_user_command("BTFormat", function()
		formatter.format_all_tasks()
	end, {})
end

return M

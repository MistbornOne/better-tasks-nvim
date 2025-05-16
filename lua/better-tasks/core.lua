local M = {}

local dateparser = require("better-tasks.dateparser")
local opts = require("better-tasks").options
local storage = require("better-tasks.storage")

-- Status Emoji Mapping
local status_emojis = {
	["TODO"] = "🆕",
	["In Progress"] = "🌱",
	["Stalled"] = "🛑",
	["Cancel"] = "🚫",
	["Done"] = "✅",
}

-- Constants
local HEADER_PREFIX_INSERTED = "Inserted from"
local HEADER_PREFIX_DONE = "Marked Done from"

--==================================
--         Helper Functions
-- =================================
-- Helper: Add header if it doesn't exist

local function ensure_header_exists(filepath, header)
	local lines = vim.fn.readfile(filepath)
	local header_line = "## " .. header
	local exists = vim.tbl_contains(lines, header_line)

	if not exists then
		table.insert(lines, "")
		table.insert(lines, header_line)
	end

	return lines
end

-- Helper: Write new task line to master
local function append_to_master(task_line)
	local short_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
	local header = os.date("%Y-%m-%d") .. " — Inserted from " .. short_path
	local path = vim.fn.stdpath("data") .. "/better-tasks/master_tasks.md"
	local lines = ensure_header_exists(path, header)
	table.insert(lines, task_line)
	vim.fn.writefile(lines, path)
end

-- Helper: Write task line to archive and remove from master
local function archive_and_remove_from_master(task_line, task_name)
	local short_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
	local header = os.date("%Y-%m-%d") .. " — Marked Done from " .. short_path
	local archive_path = vim.fn.stdpath("data") .. "/better-tasks/task_archive.md"
	local archive_lines = ensure_header_exists(archive_path, header)
	table.insert(archive_lines, task_line)
	vim.fn.writefile(archive_lines, archive_path)

	-- Remove from master
	local master_path = vim.fn.stdpath("data") .. "/better-tasks/master_tasks.md"
	local master_lines = vim.fn.readfile(master_path)
	local filtered = {}
	for _, l in ipairs(master_lines) do
		if not l:match(vim.pesc(task_name)) then
			table.insert(filtered, l)
		end
	end
	vim.fn.writefile(filtered, master_path)
end

-- =================================
-- Insert new task with user prompt
-- =================================
function M.insert_task()
	vim.ui.input({ prompt = "Task Name:" }, function(task)
		if not task or task == "" then
			return
		end

		local today = os.date("%m-%d-%Y")
		vim.ui.input({ prompt = "Due Date (MM-DD-YYYY):", default = today }, function(due_date)
			due_date = due_date == nil or due_date == "" and today or due_date

			local categories = vim.deepcopy(opts.categories or {})
			table.insert(categories, "Manual Entry")

			vim.ui.select(categories, { prompt = "Select category:" }, function(category)
				if not category then
					return
				end

				local function continue_with_category(final_category)
					if not final_category or final_category == "" then
						return
					end

					local saved_status_map = storage.load_statuses() or {}
					local saved_statuses = vim.tbl_keys(saved_status_map)
					local statuses = vim.deepcopy(opts.statuses or {})
					for _, s in ipairs(saved_statuses) do
						if not vim.tbl_contains(statuses, s) then
							table.insert(statuses, s)
						end
					end
					table.insert(statuses, "Custom Status")

					vim.ui.select(statuses, {
						prompt = "Select Status:",
						format_item = function(item)
							return string.format("%s %s", status_emojis[item] or saved_status_map[item] or "🔄", item)
						end,
					}, function(status)
						if not status then
							return
						end

						local function finalize_status(s, emoji)
							if not s or s == "" then
								return
							end
							local final_emoji = emoji or status_emojis[s] or saved_status_map[s] or "🔄"
							local date_str = "📅 " .. due_date .. " "
							local line = string.format(
								"- [ ] %s | %s | 🏷️ %s | %s %s",
								task,
								date_str,
								final_category,
								final_emoji,
								s
							)

							vim.api.nvim_put({ line }, "c", true, true)
							append_to_master(line)
						end

						if status == "Custom Status" then
							vim.ui.input({ prompt = "Enter Custom Status:" }, function(manual_status)
								if not manual_status or manual_status == "" then
									return
								end
								vim.ui.input({
									prompt = string.format(
										'Paste emoji for "%s" (e.g. ⏳, 🧠, 🚧):',
										manual_status
									),
								}, function(emoji)
									emoji = emoji == "" and "🔄" or emoji
									local current = storage.load_statuses() or {}
									current[manual_status] = emoji
									storage.save_statuses(current)
									finalize_status(manual_status, emoji)
								end)
							end)
						else
							finalize_status(status)
						end
					end)
				end

				if category == "Manual Entry" then
					vim.ui.input({ prompt = "Enter category:" }, function(manual_category)
						if not manual_category or manual_category == "" then
							return
						end
						local current = storage.load_categories() or {}
						if not vim.tbl_contains(current, manual_category) then
							table.insert(current, manual_category)
							storage.save_categories(current)
						end
						continue_with_category(manual_category)
					end)
				else
					continue_with_category(category)
				end
			end)
		end)
	end)
end

--=================================
--       Choose New Status
-- ================================
function M.set_status_prompt()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_get_current_line()

	local statuses = { "TODO", "In Progress", "Stalled", "Cancel", "Done" }

	vim.ui.select(statuses, {
		prompt = "Select new status:",
		format_item = function(item)
			return string.format("%s %s", status_emojis[item] or "🔄", item)
		end,
	}, function(choice)
		if not choice then
			return
		end

		local emoji = status_emojis[choice] or "🔄"

		-- Update checkbox and mark done if done
		if choice == "Done" then
			line = line:gsub("%- %[ %]", "- [x]")
		else
			line = line:gsub("%- %[x%]", "- [ ]")
		end

		-- Pattern: Match " <emoji> <status>" at end of line

		local updated = line:gsub("(|%s*[%z\1-\127\194-\244][\128-\191]*%s+)[^|]+$", "| " .. emoji .. " " .. choice)

		if updated ~= line then
			vim.api.nvim_buf_set_lines(0, row - 1, row, false, { updated })
		else
			vim.notify("Couldn't match status to replace", vim.log.levels.WARN)
		end
	end)
end

--====================================
--       Mark tasks as done
-- ===================================
function M.mark_done()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_get_current_line()

	local updated = line
		:gsub("%- %[ %]", "- [x]") -- check the box
		:gsub("|%s*[%z\1-\127\194-\244][\128-\191]*%s+[^|]+$", "| ✅ Done")

	vim.api.nvim_buf_set_lines(0, row - 1, row, false, { updated })

	-- === Archive task ===
	local name = updated:match("%- %[[x ]%] (.-) | 📅")
	local task = {
		raw = updated,
		name = vim.trim(name or ""),
	}

	-- Append to archive file
	local short_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
	local header = os.date("%Y-%m-%d") .. " — " .. HEADER_PREFIX_DONE .. " " .. short_path
	local archive_path = vim.fn.stdpath("data") .. "/better-tasks/task_archive.md"
	local archive_lines = vim.fn.readfile(archive_path)
	local full_header = "## " .. header
	local header_exists = false
	for _, l in ipairs(archive_lines) do
		if vim.trim(l) == full_header then
			header_exists = true
			break
		end
	end

	if not header_exists then
		table.insert(archive_lines, "")
		table.insert(archive_lines, "## " .. header)
	end

	table.insert(archive_lines, task.raw)
	vim.fn.writefile(archive_lines, archive_path)

	-- Remove from master file
	local master_path = vim.fn.stdpath("data") .. "/better-tasks/master_tasks.md"
	local master_lines = vim.fn.readfile(master_path)
	local filtered = {}

	for _, l in ipairs(master_lines) do
		if not l:match(vim.pesc(task.name)) then
			table.insert(filtered, l)
		end
	end

	vim.fn.writefile(filtered, master_path)

	vim.notify("✅ Task marked done, archived, and removed from master", vim.log.levels.INFO)
end

--===============================
--      Choose New Date in Master
--===============================

function M.set_due_date_prompt()
	local tasks = storage.read_tasks()
	local task_names = vim.tbl_map(function(task)
		return task.name
	end, tasks)

	vim.ui.select(task_names, { prompt = "Select task to change due date:" }, function(task_name)
		if not task_name then
			return
		end

		vim.ui.input({ prompt = "Enter new due date (@today, @next Friday, @May 30):" }, function(input)
			if not input or input == "" then
				return
			end

			local parsed_date = dateparser.parse(input)
			if not parsed_date then
				vim.notify("Could not parse date: " .. input, vim.log.levels.ERROR)
				return
			end

			-- 1. Update in master task list
			for _, task in ipairs(tasks) do
				if task.name == task_name then
					task.due = parsed_date
					task.raw = string.format(
						"- %s %s | 📅 %s | 🏷️ %s | %s",
						(task.status == "Done" or task.status == "✅ Done") and "[x]" or "[ ]",
						task.name,
						parsed_date,
						task.category,
						task.status
					)
					break
				end
			end
			storage.write_tasks(tasks)

			-- 2. Update in current buffer, if task is present
			local buf = vim.api.nvim_get_current_buf()
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			for i, line in ipairs(lines) do
				if line:match(vim.pesc(task_name)) then
					local updated = line:gsub("📅%s*%d%d%-%d%d%-%d%d%d%d", "📅 " .. parsed_date)
					vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { updated })
					break
				end
			end

			vim.notify("✅ Due date updated to " .. parsed_date, vim.log.levels.INFO)
		end)
	end)
end

--===========================================================
-- Open window in buffer  for editing categories and statuses
-- ==========================================================
local function open_file_popup(filepath, title)
	local buf = vim.fn.bufnr(filepath, true)
	vim.fn.bufload(buf)

	-- Avoid duplicate window
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == buf then
			vim.api.nvim_set_current_win(win)
			return
		end
	end

	-- Create floating window
	local win_width = math.floor(vim.o.columns * 0.5)
	local win_height = math.floor(vim.o.lines * 0.4)
	local row = math.floor((vim.o.lines - win_height) / 2)
	local col = math.floor((vim.o.columns - win_width) / 2)

	local win_opts = {
		relative = "editor",
		row = row,
		col = col,
		width = win_width,
		height = win_height,
		style = "minimal",
		border = "rounded",
	}

	local win = vim.api.nvim_open_win(buf, true, win_opts)
	vim.wo[win].cursorline = true
	vim.bo[buf].bufhidden = "wipe"

	vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

--=================================
-- Edit Categories in .json file
-- ================================
function M.edit_categories()
	local path = vim.fn.stdpath("config") .. "/better-tasks/categories.json"
	open_file_popup(path, "Categories")
end

--=================================
--Edit Statuses in .json file
--=================================
function M.edit_statuses()
	local path = vim.fn.stdpath("config") .. "/better-tasks/statuses.json"
	open_file_popup(path, "Statuses")
end

--=============================================
-- Open Master Tasks in Floating Buffer Window
-- ============================================
function M.open_markdown_popup(filepath, title)
	local buf = vim.fn.bufnr(filepath, true)
	vim.fn.bufload(buf)

	local stat = vim.loop.fs_stat(filepath)
	local is_new_file = stat and stat.size == 0

	if is_new_file then
		vim.api.nvim_buf_set_lines(buf, 0, 0, false, {
			"# " .. title,
			"Instructions:",
			"Use normal vim commands to interact",
			"You can edit or yank tasks as needed",
			"=======================================",
		})
	end

	local win_width = math.floor(vim.o.columns * 0.7)
	local win_height = math.floor(vim.o.lines * 0.6)
	local row = math.floor((vim.o.lines - win_height) / 2)
	local col = math.floor((vim.o.columns - win_width) / 2)

	local win_opts = {
		relative = "editor",
		row = row,
		col = col,
		width = win_width,
		height = win_height,
		style = "minimal",
		border = "rounded",
	}

	local win = vim.api.nvim_open_win(buf, true, win_opts)
	vim.wo[win].cursorline = true
	vim.bo[buf].modifiable = true
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "markdown"

	-- Optional: enable yanking
	vim.keymap.set("n", "y", '"*yy', { buffer = buf, desc = "Yank line to clipboard" })
end

--=======================================
--  Master & Archive Popup Windows
--=======================================
function M.view_master_popup()
	local path = vim.fn.stdpath("data") .. "/better-tasks/master_tasks.md"
	M.open_markdown_popup(path, "Master Tasks")
end
function M.view_archive_popup()
	local path = vim.fn.stdpath("data") .. "/better-tasks/task_archive.md"
	M.open_markdown_popup(path, "Task Archive")
end

return M

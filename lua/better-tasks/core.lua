local M = {}
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

-- Insert new task with user prompt
function M.insert_task()
	vim.ui.input({ prompt = "Task Name:" }, function(task)
		if not task or task == "" then
			return
		end

		local today = os.date("%m-%d-%Y")
		vim.ui.input({ prompt = "Due Date (MM-DD-YYYY):", default = today }, function(due_date)
			if due_date == nil or due_date == "" then
				due_date = today
			end

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

					-- Merge saved + default statuses
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
								"- [ ] %s | %s | 🏷️ %s | %s  %s",
								task,
								date_str,
								final_category,
								final_emoji,
								s
							)
							vim.api.nvim_put({ line }, "l", true, true)
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
									if not emoji or emoji == "" then
										emoji = "🔄"
									end

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

-- Choose New Status
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

-- Mark tasks as done
function M.mark_done()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_get_current_line()

	local updated = line
		:gsub("%- %[ %]", "- [x]") -- check the task box
		:gsub("|%s*[%z\1-\127\194-\244][\128-\191]*%s+[^|]+$", "| ✅ Done")

	vim.api.nvim_buf_set_lines(0, row - 1, row, false, { updated })
end

-- Open window in buffer  for editing categories and statuses
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

-- Edit Categories in .json file
function M.edit_categories()
	local path = vim.fn.stdpath("config") .. "/better-tasks/categories.json"
	open_file_popup(path, "Categories")
end

--Edit Statuses in .json file
function M.edit_statuses()
	local path = vim.fn.stdpath("config") .. "/better-tasks/statuses.json"
	open_file_popup(path, "Statuses")
end

-- Sync Daily Tasks To Archive or Master List
function M.sync_today_tasks()
	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	local open_tasks, done_tasks = {}, {}

	for _, line in ipairs(lines) do
		local is_done = line:match("%[x%]")
		local is_open = line:match("%[ ?%]") and not is_done

		if is_done or is_open then
			-- Parse fields from your format
			local name = line:match("%- %[[x ]%] (.-) | 📅")
			local due_date = line:match("📅 ([^|]+)")
			local category = line:match("🏷️ ([^|]+)")
			local status_emoji = line:match("| ([^\n|]+)$")

			local task = {
				raw = line,
				name = vim.trim(name or ""),
				due_date = vim.trim(due_date or os.date("%m-%d-%Y")),
				category = vim.trim(category or "General"),
				emoji = vim.trim(status_emoji or ""),
			}

			if is_done then
				table.insert(done_tasks, task)
			elseif is_open then
				table.insert(open_tasks, task)
			end
		end
	end

	-- Markdown header
	local short_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":~:.")
	local header = os.date("%Y-%m-%d") .. " — Synced from " .. short_path

	storage.append_open_tasks(header, open_tasks)
	storage.append_done_tasks(header, done_tasks)

	vim.notify(
		"📥 Synced " .. #open_tasks .. " open and " .. #done_tasks .. " done tasks to markdown archives.",
		vim.log.levels.INFO
	)
end

-- Open Master Tasks in Floating Buffer Window
function M.open_markdown_popup(filepath, title)
	local buf = vim.fn.bufnr(filepath, true)
	vim.fn.bufload(buf)

	vim.api.nvim_buf_set_lines(buf, 0, 0, false, {
		"# " .. title,
		"Instructions:",
		"Use normal vim commands to interact",
		"You can edit or yank tasks as needed",
		"=======================================",
	})

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

function M.view_master_popup()
	local path = vim.fn.stdpath("data") .. "/better-tasks/master_tasks.md"
	M.open_markdown_popup(path, "Master Tasks")
end
function M.view_archive_popup()
	local path = vim.fn.stdpath("data") .. "/better-tasks/task_archive.md"
	M.open_markdown_popup(path, "Task Archive")
end

return M

local M = {}
local opts = require("better-tasks").options

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
			if due_date == nil then
				return
			end
			if due_date == "" then
				due_date = today
			end

			local storage = require("better-tasks.storage")
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

					local statuses = { "TODO", "In Progress", "Stalled", "Cancel", "Done" }

					vim.ui.select(statuses, {
						prompt = "Select status:",
						format_item = function(item)
							return string.format("%s %s", status_emojis[item] or "🔄", item)
						end,
					}, function(status)
						if not status then
							return
						end

						local emoji = status_emojis[status] or "🔄"
						local date_str = "📅 " .. due_date .. " "
						local line =
							string.format("- [ ] %s %s🏷️ %s %s %s", task, date_str, final_category, emoji, status)
						vim.api.nvim_put({ line }, "l", true, true)
					end)
				end

				if category == "Manual Entry" then
					vim.ui.input({ prompt = "Enter category:" }, function(manual_category)
						if not manual_category or manual_category == "" then
							return
						end

						local current = storage.load() or {}
						if not vim.tbl_contains(current, manual_category) then
							table.insert(current, manual_category)
							storage.save(current)
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
		local updated = line:gsub(" [%z\1-\127\194-\244][\128-\191]* %a[%a%s]+$", " " .. emoji .. " " .. choice)

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
		:gsub("[%z\1-\127\194-\244][\128-\191]* %a[%a%s]+$", " ✅ Done") -- set status

	vim.api.nvim_buf_set_lines(0, row - 1, row, false, { updated })
end

return M

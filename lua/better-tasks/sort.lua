local M = {}

local function extract_due_date(line)
	local date = line:match("📅%s*(%d%d%-%d%d%-%d%d%d%d)")
	if not date then
		return 0
	end
	local y, m, d = date:sub(7), date:sub(1, 2), date:sub(4, 5)
	return os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d) }) or 0
end

local function extract_status(line)
	return line:match("|[^|]-([%z\1-\127\194-\244][\128-\191]*)%s+([%w%s]+)$") or "TODO"
end

function M.sort_buffer_tasks(opts)
	opts = opts or { sort_open_by = "date" } -- or "status"
	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	local done_tasks = {}
	local open_tasks = {}
	local task_line_indices = {}

	for i, line in ipairs(lines) do
		if line:match("^%- %[.].*📅") then
			table.insert(task_line_indices, i)
			if line:match("%[x%]") or line:match("✅ Done") then
				table.insert(done_tasks, line)
			else
				table.insert(open_tasks, line)
			end
		end
	end

	if #task_line_indices == 0 then
		vim.notify("No task lines found to sort.", vim.log.levels.WARN)
		return
	end

	if opts.sort_open_by == "date" then
		table.sort(open_tasks, function(a, b)
			return extract_due_date(a) < extract_due_date(b)
		end)
	elseif opts.sort_open_by == "status" then
		table.sort(open_tasks, function(a, b)
			return extract_status(a) < extract_status(b)
		end)
	end

	local sorted = vim.list_extend(done_tasks, open_tasks)
	for idx, i in ipairs(task_line_indices) do
		vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { sorted[idx] })
	end

	vim.notify("🗂️ Tasks sorted: done first, open sorted by " .. opts.sort_open_by, vim.log.levels.INFO)
end

return M

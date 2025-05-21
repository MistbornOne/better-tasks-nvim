local M = {}

local opts = require("better-tasks").options
local master_file = opts.master_file or ""
local archive_file = opts.archive_file or ""

-- Helper: Truncate and pad
local function truncate(str, max_len)
	if #str <= max_len then
		return str .. string.rep(" ", max_len - #str)
	else
		return str:sub(1, max_len - 3) .. "..."
	end
end

-- Format a single line into aligned columns
function M.format_task_line(line)
	local pattern = "^%s*(- %[[ xX]%])%s*(.-)%s*|%s*📅%s*(%d%d%-%d%d%-%d%d%d%d)%s*|%s*🏷️%s*(.-)%s*|%s*(.-)%s*$"

	local checkbox, name, date, tag, status = line:match(pattern)
	if not checkbox then
		return line
	end

	local name_col = truncate(name, 30)
	local date_col = truncate(date, 10)
	local tag_col = truncate(tag, 8)

	return string.format("%s %s | 📅 %s | 🏷️ %s | %s", checkbox, name_col, date_col, tag_col, status)
end

-- Format all lines in a buffer
function M.format_all_tasks(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for i, line in ipairs(lines) do
		if line:match("^%s*- %[[ xX]%]") and line:match("📅") and line:match("🏷️") then
			local formatted = M.format_task_line(line)
			if formatted ~= line then
				vim.api.nvim_buf_set_lines(bufnr, i - 1, i, false, { formatted })
			end
		end
	end
end

-- Format buffer and write to disk
function M.format_and_write_current_buffer()
	M.format_all_tasks()
	vim.cmd("write")
end

-- Show full task name in floating window if truncated
local function show_floating_message(msg)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { msg })

	local ui = vim.api.nvim_list_uis()[1]
	local width = math.min(60, #msg + 4)
	local height = 3
	local row = math.floor((ui.height - height) / 2)
	local col = math.floor((ui.width - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})

	vim.defer_fn(function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end, 3000)
end

-- When hovering a truncated task, show full name
function M.show_full_task_under_cursor()
	local line = vim.api.nvim_get_current_line()
	local pattern = "^%s*- %[[ xX]%]%s*(.-)%s*|%s*📅"
	local name = line:match(pattern)

	if not name or name:sub(-3) ~= "..." then
		return
	end

	local search_term = name:sub(1, -4) -- remove the "..."
	local files_to_search = { opts.master_file, opts.archive_file }

	for _, path in ipairs(files_to_search) do
		if path and vim.fn.filereadable(path) == 1 then
			local lines = vim.fn.readfile(path)

			for _, l in ipairs(lines) do
				local full = l:match("^%s*- %[[ xX]%]%s*(.-)%s*|%s*📅")
				if full then
					local normalized = full:gsub("%s+", " "):lower()
					local target = search_term:gsub("%s+", " "):lower()

					if normalized:sub(1, #target) == target then
						show_floating_message(full)
						return
					end
				end
			end
		end
	end

	show_floating_message("❌ No match found for: " .. search_term)
end

return M

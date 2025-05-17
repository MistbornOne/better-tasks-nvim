local M = {}

-- Paths
local config_dir = vim.fn.stdpath("config") .. "/better-tasks"
vim.fn.mkdir(config_dir, "p")

local categories_path = config_dir .. "/categories.json"
local statuses_path = config_dir .. "/statuses.json"

local data_dir = vim.fn.stdpath("data") .. "/better-tasks"
vim.fn.mkdir(data_dir, "p")

local master_file = data_dir .. "/master_tasks.md"
local archive_file = data_dir .. "/task_archive.md"

-- Helper: Ensure files exist
local function ensure_file(path, init_content)
	if vim.fn.filereadable(path) == 0 then
		vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
		local f = io.open(path, "w")
		if f then
			f:write(init_content or "")
			f:close()
		end
	end
end

ensure_file(
	master_file,
	[[
# Open Tasks
Use normal vim commands to interact
=======================================
]]
)
ensure_file(
	master_file,
	[[
# Archived Tasks
Use normal vim commands to interact
=======================================
]]
)

-- Categories

function M.load_categories()
	local ok, data = pcall(function()
		local content = table.concat(vim.fn.readfile(categories_path), "\n")
		return vim.json.decode(content)
	end)
	return ok and data or {}
end

function M.save_categories(categories)
	local json = vim.json.encode(categories)
	vim.fn.mkdir(vim.fn.fnamemodify(categories_path, ":h"), "p")
	vim.fn.writefile(vim.split(json, "\n"), categories_path)

	vim.notify("🏷️ Categories Updated", vim.log.levels.INFO)
end

-- Statuses

function M.load_statuses()
	local ok, data = pcall(function()
		local content = table.concat(vim.fn.readfile(statuses_path), "\n")
		return vim.json.decode(content)
	end)
	-- Always return a table ({} if invalid)
	if ok and type(data) == "table" then
		return data
	else
		return {}
	end
end

function M.save_statuses(status_map)
	local json = vim.json.encode(status_map)
	vim.fn.mkdir(vim.fn.fnamemodify(statuses_path, ":h"), "p")
	vim.fn.writefile(vim.split(json, "\n"), statuses_path)

	vim.notify("🧠 Statuses Updated", vim.log.levels.INFO)
end

-- Open Tasks to Master List/Done to Archive

function M.append_to_markdown(path, header, tasks)
	ensure_file(path)
	local f = io.open(path, "a")
	if not f then
		return
	end

	f:write("\n## " .. header .. "\n\n")
	for _, task in ipairs(tasks) do
		f:write(task.raw .. "\n")
	end
	f:close()
end

function M.append_open_tasks(header, tasks)
	M.append_to_markdown(master_file, header, tasks)
end

function M.write_archive(tasks)
	ensure_file(archive_file)

	local existing_lines = vim.fn.readfile(archive_file)
	local header_lines = vim.list_slice(existing_lines, 1, 4) -- Preserve top 4 header lines

	-- Build set of already archived lines
	local existing_set = {}
	for i = 5, #existing_lines do
		existing_set[existing_lines[i]] = true
	end

	-- Group new tasks by due date
	local date_groups = {}
	for _, task in ipairs(tasks) do
		if not existing_set[task.raw] then
			date_groups[task.due] = date_groups[task.due] or {}
			table.insert(date_groups[task.due], task.raw)
		end
	end

	if vim.tbl_isempty(date_groups) then
		return -- Nothing new to archive
	end

	-- Sort dates
	local sorted_dates = vim.tbl_keys(date_groups)
	table.sort(sorted_dates, function(a, b)
		return os.time({ year = a:sub(7), month = a:sub(1, 2), day = a:sub(4, 5) })
			< os.time({ year = b:sub(7), month = b:sub(1, 2), day = b:sub(4, 5) })
	end)

	-- Create new archive lines
	local new_lines = {}
	for _, date in ipairs(sorted_dates) do
		table.insert(new_lines, "")
		table.insert(new_lines, "## " .. date .. " — Synced")
		table.insert(new_lines, "")
		vim.list_extend(new_lines, date_groups[date])
	end

	-- Write updated archive
	local final_lines = vim.list_extend(existing_lines, new_lines)
	vim.fn.writefile(final_lines, archive_file)

	vim.notify("📦 Task Added To Archive", vim.log.levels.INFO)
end

-- Read Tasks For Date Picker
function M.read_tasks()
	ensure_file(master_file)
	local lines = vim.fn.readfile(master_file)
	local tasks = {}

	for _, line in ipairs(lines) do
		local status = line:match("%[([ xX])%]") == "x" and "Done" or "TODO"
		local name, due, category, raw_status = line:match("^%- %[[x ]%] (.-) %| 📅 (.-) %| 🏷️ (.-) %| (.+)$")

		if name then
			table.insert(tasks, {
				name = name,
				due = due,
				category = category,
				status = raw_status,
				raw = line,
			})
		end
	end

	return tasks
end

--============================
-- Write Tasks for Date Picker
--============================
function M.write_tasks(tasks)
	ensure_file(master_file)

	local existing_lines = vim.fn.readfile(master_file)
	local header_lines = vim.list_slice(existing_lines, 1, 3) -- 🔒 preserve top 3

	-- Group tasks by due date
	local date_groups = {}
	for _, task in ipairs(tasks) do
		local check = (task.status == "Done" or task.status == "✅ Done") and "[x]" or "[ ]"
		local status = task.status or "TODO"
		local line =
			string.format("- %s %s | 📅 %s | 🏷️ %s | %s", check, task.name, task.due, task.category, status)
		task.raw = line

		date_groups[task.due] = date_groups[task.due] or {}
		table.insert(date_groups[task.due], line)
	end

	-- Sort date keys for output
	local sorted_dates = vim.tbl_keys(date_groups)
	table.sort(sorted_dates, function(a, b)
		return os.time({ year = a:sub(7), month = a:sub(1, 2), day = a:sub(4, 5) })
			< os.time({ year = b:sub(7), month = b:sub(1, 2), day = b:sub(4, 5) })
	end)

	-- Construct task section
	local task_lines = {}
	for _, date in ipairs(sorted_dates) do
		table.insert(task_lines, "")
		table.insert(task_lines, "## " .. date .. " — Synced")
		table.insert(task_lines, "")
		vim.list_extend(task_lines, date_groups[date])
	end

	-- Combine and write back
	local new_content = vim.list_extend(header_lines, task_lines)
	vim.fn.writefile(new_content, master_file)

	vim.notify("✅ Master Task List Updated", vim.log.levels.INFO)
end

return M

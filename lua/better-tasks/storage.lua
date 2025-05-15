local M = {}

-- Paths
local config_dir = vim.fn.stdpath("config") .. "/better-tasks"
local categories_path = config_dir .. "/categories.json"
local statuses_path = config_dir .. "/statuses.json"

local data_dir = vim.fn.stdpath("data") .. "/better-tasks"
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

function M.append_done_tasks(header, tasks)
	M.append_to_markdown(archive_file, header, tasks)
end

return M

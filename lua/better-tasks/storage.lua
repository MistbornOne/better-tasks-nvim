local M = {}

-- Paths
local config_dir = vim.fn.stdpath("config") .. "/better-tasks"
local categories_path = config_dir .. "/categories.json"
local statuses_path = config_dir .. "/statuses.json"

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

return M

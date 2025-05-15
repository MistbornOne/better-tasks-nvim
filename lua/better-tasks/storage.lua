local M = {}

local json_path = vim.fn.stdpath("config") .. "/better-tasks/categories.json"

function M.load()
	local ok, data = pcall(function()
		local content = table.concat(vim.fn.readfile(json_path), "\n")
		return vim.json.decode(content)
	end)
	return ok and data or {}
end

function M.save(categories)
	local json = vim.json.encode(categories)
	vim.fn.mkdir(vim.fn.fnamemodify(json_path, ":h"), "p")
	vim.fn.writefile(vim.split(json, "\n"), json_path)
end

return M

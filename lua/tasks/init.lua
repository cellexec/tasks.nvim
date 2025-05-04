-- lua/tasks/init.lua
local M = {}

-- Function to load tasks from tasks.json
local function load_tasks()
	local task_file = vim.fn.getcwd() .. "/tasks.json"
	local tasks = {}

	-- Check if tasks.json exists
	if vim.fn.filereadable(task_file) == 1 then
		local file = io.open(task_file, "r")
		local content = file:read("*a")
		file:close()

		-- Parse JSON content into Lua table
		local success, parsed_tasks = pcall(vim.fn.json_decode, content)
		if success then
			tasks = parsed_tasks
		else
			vim.notify("Failed to parse tasks.json", vim.log.levels.ERROR)
		end
	else
		vim.notify("tasks.json not found", vim.log.levels.WARN)
	end

	return tasks
end

-- Function to display tasks using Telescope
local function display_tasks(tasks)
	local task_names = {}
	for _, task in ipairs(tasks) do
		table.insert(task_names, task.name)
	end

	-- Show task names in Telescope
	require("telescope.builtin").pickers.new({}, {
		prompt_title = "Tasks",
		finder = require("telescope.finders").new_table(task_names),
		sorter = require("telescope.sorters").get_fuzzy_file(),
	}):find()
end

-- Function to open tasks picker
function M.open_tasks()
	local tasks = load_tasks()
	if next(tasks) ~= nil then
		display_tasks(tasks)
	end
end

return M

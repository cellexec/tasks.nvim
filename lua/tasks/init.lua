local M = {}

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

local function display_tasks(tasks)
	local task_names = {}
	for _, task in ipairs(tasks) do
		table.insert(task_names, task.name)
	end

	if #task_names > 0 then
		-- Show task names in Telescope
		require("telescope.pickers").new({
			prompt_title = "Tasks",
			finder = require("telescope.finders").new_table({
				results = task_names,
				entry_maker = function(entry)
					return { value = entry, display = entry, ordinal = entry }
				end
			}),
			sorter = require("telescope.sorters").get_fuzzy_file(),
		}):find()
	else
		vim.notify("No tasks found in tasks.json", vim.log.levels.INFO)
	end
end

function M.open_tasks()
	local tasks = load_tasks()
	if next(tasks) ~= nil then
		display_tasks(tasks)
	else
		vim.notify("No tasks available", vim.log.levels.INFO)
	end
end

return M

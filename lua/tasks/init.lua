local M = {}

-- Helper function to load tasks from tasks.json
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
		-- If tasks.json doesn't exist, create it
		vim.notify("tasks.json not found. Creating a new one.", vim.log.levels.INFO)
		local file = io.open(task_file, "w")
		file:write("[]") -- Write empty JSON array
		file:close()
		vim.notify("tasks.json created.", vim.log.levels.INFO)
	end

	return tasks
end

-- Helper function to save tasks to tasks.json
local function save_tasks(tasks)
	local task_file = vim.fn.getcwd() .. "/tasks.json"
	local file = io.open(task_file, "w")
	file:write(vim.fn.json_encode(tasks))
	file:close()
end

-- Function to display tasks in Telescope
local function display_tasks(tasks)
	local task_names = {}
	for _, task in ipairs(tasks) do
		table.insert(task_names, task.name)
	end

	if #task_names > 0 then
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

-- Add a new task
local function add_task()
	local task_name = vim.fn.input("Enter task name: ")
	if task_name == "" then
		vim.notify("Task name cannot be empty.", vim.log.levels.ERROR)
		return
	end

	local task_command = vim.fn.input("Enter task command: ")
	if task_command == "" then
		vim.notify("Task command cannot be empty.", vim.log.levels.ERROR)
		return
	end

	local task_description = vim.fn.input("Enter task description: ")
	local task_created = os.date("%Y-%m-%d %H:%M:%S")

	-- Load the current tasks
	local tasks = load_tasks()

	-- Insert the new task with description and creation date
	table.insert(tasks, {
		name = task_name,
		command = task_command,
		description = task_description,
		created = task_created
	})

	-- Save the updated tasks back to tasks.json
	save_tasks(tasks)

	vim.notify("Task added successfully.", vim.log.levels.INFO)
end

-- Remove a task
local function remove_task()
	local tasks = load_tasks()
	local task_names = {}

	for _, task in ipairs(tasks) do
		table.insert(task_names, task.name)
	end

	if #task_names == 0 then
		vim.notify("No tasks to remove.", vim.log.levels.INFO)
		return
	end

	-- Prompt user to select task to remove
	local selected_task = require("telescope.pickers").new({
		prompt_title = "Select Task to Remove",
		finder = require("telescope.finders").new_table({
			results = task_names,
			entry_maker = function(entry)
				return { value = entry, display = entry, ordinal = entry }
			end
		}),
		sorter = require("telescope.sorters").get_fuzzy_file(),
		attach_mappings = function(prompt_bufnr)
			local action_state = require("telescope.actions.state")
			local selection = action_state.get_selected_entry()
			local index = nil
			for i, task in ipairs(tasks) do
				if task.name == selection.value then
					index = i
					break
				end
			end

			-- Remove the selected task
			if index then
				table.remove(tasks, index)

				-- Save the updated tasks back to tasks.json
				save_tasks(tasks)

				vim.notify("Task removed successfully.", vim.log.levels.INFO)
			end
			return true
		end
	}):find()
end

-- Edit a task
local function edit_task()
	local tasks = load_tasks()
	local task_names = {}

	for i, task in ipairs(tasks) do
		table.insert(task_names, task.name)
	end

	if #task_names == 0 then
		vim.notify("No tasks to edit.", vim.log.levels.INFO)
		return
	end

	-- Prompt user to select task to edit
	local selected_task = require("telescope.pickers").new({
		prompt_title = "Select Task to Edit",
		finder = require("telescope.finders").new_table({
			results = task_names,
			entry_maker = function(entry)
				return { value = entry, display = entry, ordinal = entry }
			end
		}),
		sorter = require("telescope.sorters").get_fuzzy_file(),
		attach_mappings = function(prompt_bufnr)
			local action_state = require("telescope.actions.state")
			local selection = action_state.get_selected_entry()

			local task_to_edit = nil
			for i, task in ipairs(tasks) do
				if task.name == selection.value then
					task_to_edit = task
					break
				end
			end

			if task_to_edit then
				-- Prompt user for new name, command, and description
				local new_name = vim.fn.input("Edit task name: ", task_to_edit.name)
				local new_command = vim.fn.input("Edit task command: ", task_to_edit.command)
				local new_description = vim.fn.input("Edit task description: ", task_to_edit.description)

				if new_name ~= "" then
					task_to_edit.name = new_name
				end
				if new_command ~= "" then
					task_to_edit.command = new_command
				end
				if new_description ~= "" then
					task_to_edit.description = new_description
				end

				-- Save the updated tasks back to tasks.json
				save_tasks(tasks)

				vim.notify("Task updated successfully.", vim.log.levels.INFO)
			end
			return true
		end
	}):find()
end

-- Main function to open tasks with Telescope and allow actions
function M.open_tasks()
	local tasks = load_tasks()
	display_tasks(tasks)
end

-- Expose the functions to be used externally
M.add_task = add_task
M.remove_task = remove_task
M.edit_task = edit_task

return M

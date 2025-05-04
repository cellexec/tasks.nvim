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

	-- Load the current tasks
	local tasks = load_tasks()
	table.insert(tasks, { name = task_name, command = task_command })

	-- Save the updated tasks back to tasks.json
	local task_file = vim.fn.getcwd() .. "/tasks.json"
	local file = io.open(task_file, "w")
	file:write(vim.fn.json_encode(tasks))
	file:close()

	vim.notify("Task added successfully.", vim.log.levels.INFO)
end

-- Remove a task
local function remove_task(tasks)
	local task_names = {}
	for i, task in ipairs(tasks) do
		table.insert(task_names, task.name)
	end

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
				local task_file = vim.fn.getcwd() .. "/tasks.json"
				local file = io.open(task_file, "w")
				file:write(vim.fn.json_encode(tasks))
				file:close()

				vim.notify("Task removed successfully.", vim.log.levels.INFO)
			end
			return true
		end
	}):find()
end

-- Edit a task
local function edit_task(tasks)
	local task_names = {}
	for i, task in ipairs(tasks) do
		table.insert(task_names, task.name)
	end

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
				-- Prompt user for new name and command
				local new_name = vim.fn.input("Edit task name: ", task_to_edit.name)
				local new_command = vim.fn.input("Edit task command: ", task_to_edit.command)

				if new_name ~= "" then
					task_to_edit.name = new_name
				end
				if new_command ~= "" then
					task_to_edit.command = new_command
				end

				-- Save the updated tasks back to tasks.json
				local task_file = vim.fn.getcwd() .. "/tasks.json"
				local file = io.open(task_file, "w")
				file:write(vim.fn.json_encode(tasks))
				file:close()

				vim.notify("Task updated successfully.", vim.log.levels.INFO)
			end
			return true
		end
	}):find()
end

-- Main function to open tasks with Telescope and allow actions
function M.open_tasks()
	local tasks = load_tasks()
	local task_names = {}

	for _, task in ipairs(tasks) do
		table.insert(task_names, task.name)
	end

	require("telescope.pickers").new({
		prompt_title = "Tasks",
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

			-- Task actions
			if selection then
				local task_to_edit = nil
				for _, task in ipairs(tasks) do
					if task.name == selection.value then
						task_to_edit = task
						break
					end
				end

				if task_to_edit then
					vim.api.nvim_set_keymap("n", "<leader>ta", ":lua require('tasks').add_task()<CR>",
						{ noremap = true, silent = true })
					vim.api.nvim_set_keymap("n", "<leader>tr", ":lua require('tasks').remove_task(tasks)<CR>",
						{ noremap = true, silent = true })
					vim.api.nvim_set_keymap("n", "<leader>te", ":lua require('tasks').edit_task(tasks)<CR>",
						{ noremap = true, silent = true })
				end
			end

			return true
		end
	}):find()
end

-- Expose the functions to be used externally
M.add_task = add_task
M.remove_task = remove_task
M.edit_task = edit_task

return M

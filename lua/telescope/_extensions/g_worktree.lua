---@diagnostic disable: undefined-global
local utils = require("telescope.utils")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local action_set = require("telescope.actions.set")
local g_worktree = require("g-worktree")

local remove_worktree = function(buf)
	actions.close(buf)
	local selected = action_state.get_selected_entry(buf)
	local delete_confirm = vim.fn.input("Do you want to delete this branch permanently ? [y/N]: ")

	if delete_confirm ~= "y" then
		return
	end

	vim.print(" \n")
	g_worktree.remove_worktree(selected.display)
end

local git_worktree_list = function(opts)
	opts = opts or {}
	local wt_list_output = utils.get_os_command_output({ "git", "worktree", "list" })
	local results = {}

	for _, value in pairs(wt_list_output) do
		local branch_name = value:match("%[(.-)%]")
		local wt_path = value:match("[^%s]+")
		table.insert(results, { branch = branch_name, path = wt_path })
	end

	pickers
		.new(opts, {
			prompt_title = "git worktrees",
			finder = finders.new_table({
				results = results,
				entry_maker = function(entry)
					return {
						value = entry.path,
						ordinal = entry.branch,
						display = entry.branch,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(_, map)
				action_set.select:replace(function(buf)
					local selection = action_state.get_selected_entry(buf)
					if selection ~= nil then
						actions.close(buf)
						g_worktree.switch_worktree(selection.display)
					end
				end)
				map("i", "<c-d>", remove_worktree)
				map("n", "<c-d>", remove_worktree)
				return true
			end,
		})
		:find()
end

local function git_worktree_create(opts)
	local opts = opts or {}
	opts.attach_mappings = function()
		actions.select_default:replace(function(buf, _)
			local selected = action_state.get_selected_entry()
			actions.close(buf)
			g_worktree.create_worktree(selected.value)
		end)
		return true
	end

	require("telescope.builtin").git_branches(opts)
end

return require("telescope").register_extension({
	exports = {
		list = git_worktree_list,
		create = git_worktree_create,
	},
})

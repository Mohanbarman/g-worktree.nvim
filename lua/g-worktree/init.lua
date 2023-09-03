---@diagnostic disable: undefined-global
local Job = require("plenary.Job")
local Path = require("plenary.Path")

local M = {}
local cwd = vim.loop.cwd()

-- resolve the path needed to create worktree in
-- uses the pattern provided in setup to create path
local function _resolve_wt_path(branch_name)
	local stdout, status = Job:new({
		command = "git",
		args = { "rev-parse", "--git-dir" },
		cwd = cwd,
	}):sync()

	if status ~= 0 then
		return nil
	end

	local git_dir_path = Path:new(stdout[1]):absolute()
	local git_dir_name = string.match(git_dir_path, "([^/]+)/.git/?[^/]*")
	local git_dir_base_path = string.match(git_dir_path, "(.+)/.git")

	local resolved_base_dir_pattern = string.gsub(
		string.gsub(M._config.base_dir_pattern, "{git_dir_name}", git_dir_name),
		"{branch_name}",
		branch_name
	)

	local final_path = Path:new():joinpath(git_dir_base_path, resolved_base_dir_pattern):absolute()
	return final_path
end

local function _is_inside_git_repo()
	local _, status = Job:new({
		command = "git",
		args = { "status" },
		cwd = cwd,
	}):sync()

	return status == 0
end

-- Setup configuration for git worktree
-- @param opts
-- @field pick_dir function to pick base dir of worktree
M.setup = function(opts)
	opts = opts or {}
	M._config = vim.tbl_deep_extend("force", {
		base_dir_pattern = "../{git_dir_name}-wt/{branch_name}",
		post_create_cmd = "Explore .",
		change_dir_after_create = true,
		clearjumps = true,
	}, opts)
end

local function _create_worktree_job(path, branch)
	local stdout, status = Job:new({
		command = "git",
		args = { "worktree", "add", path, branch },
		on_stderr = function(error, data, job)
			vim.print(data)
		end,
	}):sync()

	if status ~= 0 then
		return false
	end

	return true
end

local function _worktree_list_job()
	local stdout, status_code = Job:new({
		command = "git",
		args = { "worktree", "list" },
		cwd = cwd,
		on_stderr = function(error, data, job)
			vim.print(data)
		end,
	}):sync()

	if status_code ~= 0 then
		return nil
	end

	return stdout
end

local function _remove_worktree_job(wt_path)
	local _, status_code = Job:new({
		command = "git",
		args = { "worktree", "remove", wt_path, "--force" },
		cwd = cwd,
		on_stderr = function(_, data, _)
			vim.print(data)
		end,
	}):sync()

	if status_code ~= 0 then
		return nil
	end

	return true
end

local function _find_worktree_path(branch_name)
	local wt_branches = _worktree_list_job()

	if wt_branches == nil then
		vim.print("failed to get worktrees list")
		return
	end

	local wt_path = nil

	for _, value in pairs(wt_branches) do
		local wt_branch_name = value:match("%[(.-)%]")
		if wt_branch_name == branch_name then
			wt_path = value:match("[^%s]+")
		end
	end

	return wt_path
end

M.remove_worktree = function(branch_name)
	local wt_path = _find_worktree_path(branch_name)

	if wt_path == nil then
		vim.print("failed to find worktree path")
		return
	end

	local removed_wt = _remove_worktree_job(wt_path)
	if removed_wt == nil then
		return
	end

	vim.print("worktree removed: " .. wt_path)
end

M.switch_worktree = function(branch_name)
	local wt_path = _find_worktree_path(branch_name)

	if wt_path == nil then
		vim.print("failed to find worktree")
		return
	end

	if M._config.change_dir_after_create then
		vim.cmd("cd " .. wt_path)
	end
	if M._config.post_create_cmd then
		vim.cmd(M._config.post_create_cmd)
	end
	if M._config.clearjumps then
		vim.cmd("clearjumps")
	end

	vim.print("switched to " .. wt_path)
end

M.create_worktree = function(branch_name)
	local is_inside_git_repo = _is_inside_git_repo()

	if not is_inside_git_repo then
		vim.print("not inside git repo")
		return
	end

	local worktree_path = _resolve_wt_path(branch_name)
	local wt_created = _create_worktree_job(worktree_path, branch_name)

	if not wt_created then
		return
	end

	if M._config.change_dir_after_create then
		M.switch_worktree(branch_name)
	end

	vim.print("worktree created")
end

return M

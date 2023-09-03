# g-worktree.nvim
A better git worktree integration for neovim

# Installation
## Packer
```lua
return require("packer").startup(function(use)
  use({ "Mohanbarman/g-worktree.nvim" })
end)
```

## Setup
This is the default configuration
```lua
M.setup({
  -- this pattern is used while deciding the directory to use for worktree, it's relative to your main git repo's path
  base_dir_pattern = "../{git_dir_name}-wt/{branch_name}",
  post_create_cmd = "Explore .", -- you can use any vim cmd in this case default netrw window will open 
  change_dir_after_create = true, -- do you want to switch current directory after create ?
  clearjumps = true,
})
```

## Usage
### Creating worktree
```lua
require('g-worktree').create_worktree('<BRANCH_NAME>')
```
### Switch to different worktree
```lua
require('g-worktree').switch_worktree('<BRANCH_NAME>')
```
### Deleting a worktree
```lua
require('g-worktree').remove_worktree('<BRANCH_NAME>')
```

## Telescope
```lua
require("telescope").load_extension("g_worktree") -- load telescope extension

-- switch worktree
require('telescope').extensions.g_worktree.list()

-- create worktree
require('telescope').extensions.g_worktree.create()
```

# package-pilot.nvim

A Neovim plugin that helps you manage and execute JavaScript/TypeScript project scripts from within Neovim. Intelligently detects your package manager (npm, yarn, pnpm, bun) and provides utilities to run your project scripts.

> This plugin basically copies most code from the utils of the great [overseer](https://github.com/stevearc/overseer.nvim) plugin, this is just to expose the functionality in case others want to use it.

## Features

- Auto-detects package managers (npm, yarn, pnpm, bun)
- Finds package.json files in your project hierarchy
- Lists available scripts from package.json
- Supports projects with workspaces
- Detect run command based on package manager

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "banjo/package-pilot.nvim",
}
```

## Usage

### Basic Usage

```lua
-- Find package.json and detect package manager
local pilot = require("package-pilot")
local dir = vim.fn.expand("%:p:h")
local package_file = pilot.find_package_file({ dir = dir })
local package_manager = pilot.detect_package_manager(package_file)

-- Get all scripts and run command
local scripts = pilot.get_all_scripts(package_file)
local run_cmd = pilot.get_run_command(package_manager)
```

## API Reference

### `find_package_file(opts)`

Finds package.json files with scripts or workspaces.

### `detect_package_manager(package_file)`

Returns "npm", "yarn", "pnpm", or "bun" based on lock files.

### `get_all_scripts(package)`

Gets all script names from package.json, including workspaces.

### `get_run_command(package_manager)`

Returns the appropriate run command (e.g., "npm run", "yarn").

### `get_dependencies(package)`

Gets all dependencies and devDependencies from the specified `package.json` file. Returns a list of tables, where each table has `name` (string), `version` (string), and `dev` (boolean) fields.

```

```

local files = require("package-pilot.files")

local M = {}

---@type table<string, string[]>
local mgr_lockfiles = {
  npm = { "package-lock.json" },
  pnpm = { "pnpm-lock.yaml" },
  yarn = { "yarn.lock" },
  bun = { "bun.lockb", "bun.lock" },
}

---@type table<string, string>
local run_commands = {
  npm = "npm run",
  pnpm = "pnpm run",
  yarn = "yarn",
  bun = "bun",
}

---@generic T : any
---@param list T[]
---@param cb fun(item: T): boolean
---@return boolean
local function list_any(list, cb)
  for _, v in ipairs(list) do
    if cb(v) then
      return true
    end
  end
  return false
end

---@class SearchParams
---@field dir string

---@param opts SearchParams
local function get_candidate_package_files(opts)
  -- Some projects have package.json files in subfolders, which are not the main project package.json file,
  -- but rather some submodule marker. This seems prevalent in react-native projects. See this for instance:
  -- https://stackoverflow.com/questions/51701191/react-native-has-something-to-use-local-folders-as-package-name-what-is-it-ca
  -- To cover that case, we search for package.json files starting from the current file folder, up to the
  -- working directory
  local matches = vim.fs.find("package.json", {
    upward = true,
    type = "file",
    path = opts.dir,
    stop = vim.fn.getcwd() .. "/..",
    limit = math.huge,
  })
  if #matches > 0 then
    return matches
  end
  -- we couldn't find any match up to the working directory.
  -- let's now search for any possible single match without
  -- limiting ourselves to the working directory.
  return vim.fs.find("package.json", {
    upward = true,
    type = "file",
    path = vim.fn.getcwd(),
  })
end

--- Find the package.json files in the project. The search starts from the current file's directory. It will only include package.json that has either `scripts` or `workspaces` field.
---@param opts SearchParams
---@return string|nil
function M.find_package_file(opts)
  local candidate_packages = get_candidate_package_files(opts)
  -- go through candidate package files from closest to the file to least close
  for _, package in ipairs(candidate_packages) do
    local data = files.load_json_file(package)
    if data.scripts or data.workspaces then
      return package
    end
  end
  return nil
end

---Get the package manager used in a project based on lockfiles.
---@param package_file string The path to the package.json file
---@return string The detected package manager name ("npm", "yarn", "pnpm", etc) or "npm" as fallback
function M.detect_package_manager(package_file)
  local package_dir = vim.fs.dirname(package_file)
  for mgr, lockfiles in pairs(mgr_lockfiles) do
    if list_any(lockfiles, function(lockfile)
      return files.exists(files.join(package_dir, lockfile))
    end) then
      return mgr
    end
  end
  return "npm"
end

---@param package string -- path to package.json file
---@return string[] -- list of all scripts in the package.json file
function M.get_all_scripts(package)
  local data = files.load_json_file(package)
  local ret = {}
  if data.scripts then
    for script in pairs(data.scripts) do
      table.insert(ret, script)
    end
  end

  -- Load tasks from workspaces
  if data.workspaces then
    for _, workspace in ipairs(data.workspaces) do
      local workspace_path = files.join(vim.fs.dirname(package), workspace)
      local workspace_package_file = files.join(workspace_path, "package.json")
      local workspace_data = files.load_json_file(workspace_package_file)
      if workspace_data and workspace_data.scripts then
        for script in pairs(workspace_data.scripts) do
          table.insert(ret, script)
        end
      end
    end
  end
  return ret
end

--- Get the run command for a package manager
---@param package_manager string -- package manager name ("npm", "yarn", "pnpm", etc)
---@return string -- run command for the package manager (e.g. "npm run", "yarn", etc)
function M.get_run_command(package_manager)
  local cmd = run_commands[package_manager]

  if not cmd then
    return run_commands.npm
  end

  return cmd
end

return M

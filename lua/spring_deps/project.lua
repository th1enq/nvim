local M = {}

local build_files = {
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
}

local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local content = file:read "*a"
  file:close()
  return content
end

local function maven_boot_version(content)
  local function resolve(version)
    local property = version and version:match "^%${([^}]+)}$"
    if property then
      return content:match("<" .. vim.pesc(property) .. ">%s*([^<%s]+)%s*</" .. vim.pesc(property) .. ">")
    end
    return version
  end

  local parent = content:match "<parent>(.-)</parent>"
  if parent
    and parent:match "<groupId>%s*org%.springframework%.boot%s*</groupId>"
    and parent:match "<artifactId>%s*spring%-boot%-starter%-parent%s*</artifactId>"
  then
    return resolve(parent:match "<version>%s*([^<%s]+)%s*</version>")
  end

  return resolve(
    content:match "<spring%-boot%.version>%s*([^<%s]+)%s*</spring%-boot%.version>"
      or content:match "<artifactId>%s*spring%-boot%-dependencies%s*</artifactId>%s*<version>%s*([^<%s]+)%s*</version>"
      or content:match "<artifactId>%s*spring%-boot%-maven%-plugin%s*</artifactId>%s*<version>%s*([^<%s]+)%s*</version>"
  )
end

local function gradle_boot_version(content)
  return content:match "id%s*%(?%s*['\"]org%.springframework%.boot['\"]%)?%s*version%s*%(?%s*['\"]([^'\"]+)['\"]"
end

function M.detect(opts)
  opts = opts or {}
  local start_dir = opts.start_dir
    or vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    or vim.uv.cwd()

  if start_dir == "" then
    start_dir = vim.uv.cwd()
  end

  local candidates = {}
  local directory = vim.fs.normalize(start_dir)

  while directory do
    for _, name in ipairs(build_files) do
      local path = directory .. "/" .. name
      if vim.uv.fs_stat(path) then
        table.insert(candidates, path)
      end
    end

    if #candidates > 0 then
      break
    end

    local parent = vim.fs.dirname(directory)
    if not parent or parent == directory then
      break
    end
    directory = parent
  end

  local path = candidates[1]
  if path then
    local name = vim.fs.basename(path)
    local content = read_file(path)
    local kind = name == "pom.xml" and "maven" or "gradle"
    local dsl = name == "build.gradle.kts" and "kotlin" or "groovy"
    local boot_version = kind == "maven" and maven_boot_version(content or "")
      or gradle_boot_version(content or "")

    return {
      root = vim.fs.dirname(path),
      path = path,
      filename = name,
      kind = kind,
      dsl = dsl,
      boot_version = boot_version,
    }
  end

  return nil
end

M.maven_boot_version = maven_boot_version
M.gradle_boot_version = gradle_boot_version

return M

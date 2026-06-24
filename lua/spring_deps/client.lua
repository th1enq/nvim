local M = {}

local accept = "application/vnd.initializr.v2.2+json"
local user_agent = "nvim-spring-deps/0.1.0"

local function join_url(base, path)
  return base:gsub("/+$", "") .. path
end

local function request_json(url, callback)
  vim.system({
    "curl",
    "-fsSL",
    "--connect-timeout",
    "5",
    "--max-time",
    "20",
    "-H",
    "Accept: " .. accept,
    "-H",
    "User-Agent: " .. user_agent,
    url,
  }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback(nil, vim.trim(result.stderr or "Spring Initializr request failed"))
        return
      end

      local ok, decoded = pcall(vim.json.decode, result.stdout)
      if not ok then
        callback(nil, "Spring Initializr returned invalid JSON")
        return
      end

      callback(decoded)
    end)
  end)
end

local function catalog_items(metadata, resolved)
  local items = {}
  local coordinates = resolved.dependencies or {}

  for _, group in ipairs(metadata.dependencies.values or {}) do
    for _, dependency in ipairs(group.values or {}) do
      local coordinate = coordinates[dependency.id]
      if coordinate then
        table.insert(items, vim.tbl_extend("force", dependency, {
          category = group.name,
          coordinate = coordinate,
          bom_data = coordinate.bom and resolved.boms[coordinate.bom] or nil,
          repository_data = coordinate.repository and resolved.repositories[coordinate.repository] or nil,
          repository_id = coordinate.repository,
        }))
      end
    end
  end

  return items
end

function M.fetch(opts, callback)
  local base_url = opts.base_url
  local boot_version = opts.boot_version
  local metadata
  local resolved
  local failed = false

  local function finish()
    if failed or not metadata or not resolved then
      return
    end

    callback({
      items = catalog_items(metadata, resolved),
      boot_version = resolved.bootVersion,
    })
  end

  local function handle_error(err)
    if failed then
      return
    end
    failed = true
    callback(nil, err)
  end

  request_json(join_url(base_url, "/"), function(data, err)
    if err then
      handle_error(err)
      return
    end
    metadata = data
    finish()
  end)

  request_json(
    join_url(base_url, "/dependencies?bootVersion=" .. vim.uri_encode(boot_version)),
    function(data, err)
      if err then
        handle_error(err)
        return
      end
      resolved = data
      finish()
    end
  )
end

return M

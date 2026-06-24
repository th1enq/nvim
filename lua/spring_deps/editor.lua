local M = {}

local function read_lines(path)
  return vim.fn.readfile(path)
end

local function write_lines(path, lines)
  vim.fn.writefile(lines, path)
end

local function leading_space(line)
  return line:match "^(%s*)" or ""
end

local function contains_coordinate(lines, dependency)
  local needle = dependency.groupId .. ":" .. dependency.artifactId
  local joined = table.concat(lines, "\n")
  if joined:find(needle, 1, true) then
    return true
  end

  for block in joined:gmatch "<dependency>(.-)</dependency>" do
    local group_id = block:match "<groupId>%s*([^<%s]+)%s*</groupId>"
    local artifact_id = block:match "<artifactId>%s*([^<%s]+)%s*</artifactId>"
    if group_id == dependency.groupId and artifact_id == dependency.artifactId then
      return true
    end
  end

  return false
end

local function find_xml_block(lines, tag, parent_tag)
  local stack = {}

  for index, line in ipairs(lines) do
    for token in line:gmatch "<[^>]+>" do
      local closing_name = token:match "^</%s*([%w_.-]+)"
      local opening_name = token:match "^<%s*([%w_.-]+)"

      if closing_name then
        local name = closing_name
        if stack[#stack] and stack[#stack].name == name then
          local node = table.remove(stack)
          if name == tag and (not parent_tag or (stack[#stack] and stack[#stack].name == parent_tag)) then
            return node.line, index
          end
        end
      elseif opening_name and not token:match "/%s*>$" then
        table.insert(stack, { name = opening_name, line = index })
      end
    end
  end
end

local function maven_dependency_lines(dependency, indent)
  local lines = {
    indent .. "<dependency>",
    indent .. "  <groupId>" .. dependency.groupId .. "</groupId>",
    indent .. "  <artifactId>" .. dependency.artifactId .. "</artifactId>",
  }

  if dependency.version then
    table.insert(lines, indent .. "  <version>" .. dependency.version .. "</version>")
  end

  if dependency.scope == "runtime" or dependency.scope == "test" then
    table.insert(lines, indent .. "  <scope>" .. dependency.scope .. "</scope>")
  elseif dependency.scope == "annotationProcessor" then
    table.insert(lines, indent .. "  <optional>true</optional>")
  end

  table.insert(lines, indent .. "</dependency>")
  return lines
end

local function insert_all(lines, index, additions)
  for offset, line in ipairs(additions) do
    table.insert(lines, index + offset - 1, line)
  end
end

local function add_maven_bom(lines, bom)
  if not bom or contains_coordinate(lines, bom) then
    return false
  end

  local dependencies_start, dependencies_end = find_xml_block(lines, "dependencies", "dependencyManagement")
  local dependency_lines

  if dependencies_start then
    local indent = leading_space(lines[dependencies_end])
    dependency_lines = maven_dependency_lines(vim.tbl_extend("force", bom, {
      scope = "import",
    }), indent .. "  ")
    table.insert(dependency_lines, #dependency_lines, indent .. "    <type>pom</type>")
    table.insert(dependency_lines, #dependency_lines, indent .. "    <scope>import</scope>")
    insert_all(lines, dependencies_end, dependency_lines)
    return true
  end

  local _, project_end = find_xml_block(lines, "project")
  if not project_end then
    return false
  end

  local block = {
    "  <dependencyManagement>",
    "    <dependencies>",
  }
  vim.list_extend(block, maven_dependency_lines(vim.tbl_extend("force", bom, {
    scope = "import",
  }), "      "))
  table.insert(block, #block, "        <type>pom</type>")
  table.insert(block, #block, "        <scope>import</scope>")
  vim.list_extend(block, {
    "    </dependencies>",
    "  </dependencyManagement>",
    "",
  })
  insert_all(lines, project_end, block)
  return true
end

local function add_maven_repository(lines, id, repository)
  if not repository or not repository.url then
    return false
  end

  local joined = table.concat(lines, "\n")
  if joined:find(repository.url, 1, true) then
    return false
  end

  local _, repositories_end = find_xml_block(lines, "repositories", "project")
  local repository_lines
  if repositories_end then
    local indent = leading_space(lines[repositories_end]) .. "  "
    repository_lines = {
      indent .. "<repository>",
      indent .. "  <id>" .. id .. "</id>",
      indent .. "  <name>" .. (repository.name or id) .. "</name>",
      indent .. "  <url>" .. repository.url .. "</url>",
      indent .. "</repository>",
    }
    insert_all(lines, repositories_end, repository_lines)
    return true
  end

  local _, project_end = find_xml_block(lines, "project")
  if not project_end then
    return false
  end

  repository_lines = {
    "  <repositories>",
    "    <repository>",
    "      <id>" .. id .. "</id>",
    "      <name>" .. (repository.name or id) .. "</name>",
    "      <url>" .. repository.url .. "</url>",
    "    </repository>",
    "  </repositories>",
    "",
  }
  insert_all(lines, project_end, repository_lines)
  return true
end

local function add_maven(lines, item)
  local dependency = item.coordinate
  if contains_coordinate(lines, dependency) then
    return false
  end

  add_maven_bom(lines, item.bom_data)
  add_maven_repository(lines, item.repository_id, item.repository_data)

  local start_index, end_index = find_xml_block(lines, "dependencies", "project")
  local additions

  if start_index then
    local indent = leading_space(lines[end_index]) .. "  "
    additions = maven_dependency_lines(dependency, indent)
    insert_all(lines, end_index, additions)
  else
    local project_start, project_end = find_xml_block(lines, "project")
    if not project_start then
      return false, "Invalid pom.xml: missing <project>"
    end
    additions = { "  <dependencies>" }
    vim.list_extend(additions, maven_dependency_lines(dependency, "    "))
    vim.list_extend(additions, { "  </dependencies>", "" })
    insert_all(lines, project_end, additions)
  end

  return true
end

local gradle_scopes = {
  compile = "implementation",
  runtime = "runtimeOnly",
  test = "testImplementation",
}

local function gradle_notation(dependency, dsl)
  local coordinate = dependency.groupId .. ":" .. dependency.artifactId
  if dependency.version then
    coordinate = coordinate .. ":" .. dependency.version
  end

  local configurations = dependency.scope == "annotationProcessor"
      and { "compileOnly", "annotationProcessor" }
    or { gradle_scopes[dependency.scope] or "implementation" }
  local lines = {}

  for _, configuration in ipairs(configurations) do
    if dsl == "kotlin" then
      table.insert(lines, configuration .. '("' .. coordinate .. '")')
    else
      table.insert(lines, configuration .. " '" .. coordinate .. "'")
    end
  end

  return lines
end

local function find_gradle_block(lines, block_name)
  local depth = 0
  local start_index

  for index, line in ipairs(lines) do
    if not start_index and line:match("^%s*" .. block_name .. "%s*{") then
      start_index = index
    end

    if start_index then
      local opens = select(2, line:gsub("{", ""))
      local closes = select(2, line:gsub("}", ""))
      depth = depth + opens - closes
      if depth == 0 then
        return start_index, index
      end
    end
  end
end

local function add_gradle_repository(lines, repository, dsl)
  if not repository or not repository.url then
    return false
  end
  if table.concat(lines, "\n"):find(repository.url, 1, true) then
    return false
  end

  local _, end_index = find_gradle_block(lines, "repositories")
  local line = dsl == "kotlin" and '  maven { url = uri("' .. repository.url .. '") }'
    or "  maven { url = uri('" .. repository.url .. "') }"

  if end_index then
    table.insert(lines, end_index, leading_space(lines[end_index]) .. vim.trim(line))
  else
    vim.list_extend(lines, {
      "",
      "repositories {",
      line,
      "}",
    })
  end
  return true
end

local function add_gradle(lines, item, dsl)
  local dependency = item.coordinate
  if contains_coordinate(lines, dependency) then
    return false
  end

  add_gradle_repository(lines, item.repository_data, dsl)

  local start_index, end_index = find_gradle_block(lines, "dependencies")
  if not start_index then
    table.insert(lines, "")
    table.insert(lines, "dependencies {")
    table.insert(lines, "}")
    start_index, end_index = #lines - 1, #lines
  end

  local indent = leading_space(lines[end_index]) .. "  "
  local additions = {}

  if item.bom_data and not contains_coordinate(lines, item.bom_data) then
    local bom = item.bom_data.groupId .. ":" .. item.bom_data.artifactId .. ":" .. item.bom_data.version
    table.insert(
      additions,
      dsl == "kotlin" and indent .. 'implementation(platform("' .. bom .. '"))'
        or indent .. "implementation platform('" .. bom .. "')"
    )
  end

  for _, notation in ipairs(gradle_notation(dependency, dsl)) do
    table.insert(additions, indent .. notation)
  end

  insert_all(lines, end_index, additions)
  return true
end

function M.add(project, items)
  local lines = read_lines(project.path)
  local added = {}
  local skipped = {}

  for _, item in ipairs(items) do
    local ok, err
    if project.kind == "maven" then
      ok, err = add_maven(lines, item)
    else
      ok, err = add_gradle(lines, item, project.dsl)
    end

    if err then
      return nil, err
    elseif ok then
      table.insert(added, item.name)
    else
      table.insert(skipped, item.name)
    end
  end

  if #added > 0 then
    write_lines(project.path, lines)
    local buffer = vim.fn.bufnr(project.path)
    if buffer ~= -1 and vim.api.nvim_buf_is_loaded(buffer) then
      vim.api.nvim_buf_call(buffer, function()
        vim.cmd "checktime"
      end)
    end
  end

  return {
    added = added,
    skipped = skipped,
  }
end

M._find_xml_block = find_xml_block
M._find_gradle_dependencies = function(lines)
  return find_gradle_block(lines, "dependencies")
end

return M

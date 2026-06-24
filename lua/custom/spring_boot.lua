local function package_from_path(path)
  local markers = {
    "src/main/java/",
    "src/test/java/",
  }

  for _, marker in ipairs(markers) do
    local idx = path:find(marker, 1, true)

    if idx then
      local pkg_path = path:sub(idx + #marker)
      pkg_path = vim.fn.fnamemodify(pkg_path, ":h")
      pkg_path = pkg_path:gsub("/", ".")
      pkg_path = pkg_path:gsub("%.$", "")

      if pkg_path == "." then
        return nil
      end

      return pkg_path
    end
  end

  return nil
end

local function is_buffer_empty()
  return vim.api.nvim_buf_line_count(0) == 1
    and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == ""
end

local function create_java_template()
  local file_path = vim.fn.expand("%:p")

  if file_path == "" then
    return
  end

  if not file_path:match("%.java$") then
    return
  end

  if not is_buffer_empty() then
    return
  end

  local class_name = vim.fn.expand("%:t:r")
  local package_name = package_from_path(file_path)

  local lines = {}

  if package_name and package_name ~= "" then
    table.insert(lines, "package " .. package_name .. ";")
    table.insert(lines, "")
  end

  table.insert(lines, "public class " .. class_name .. " {")
  table.insert(lines, "}")
  table.insert(lines, "")

  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = "java"
end

vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
  pattern = {
    "*/src/main/java/**/*.java",
    "*/src/test/java/**/*.java",
  },
  callback = function()
    vim.schedule(create_java_template)
  end,
})

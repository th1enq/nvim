local M = {}

local MAX_FILES = 5

local ignore = {
  [".git"] = true,
  ["node_modules"] = true,
}

local function scan_dir(path, prefix, lines)
  local handle = vim.loop.fs_scandir(path)
  if not handle then return end

  local dirs = {}
  local files = {}

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end

    if not ignore[name] then
      if type == "directory" then
        table.insert(dirs, name)
      else
        table.insert(files, name)
      end
    end
  end

  -- sort
  table.sort(dirs)
  table.sort(files)

  -- ===== show folders FIRST =====
  for _, dir in ipairs(dirs) do
    table.insert(lines, prefix .. dir)
    scan_dir(path .. "/" .. dir, prefix .. "│   ", lines)
  end

  -- ===== show limited files =====
  local total_files = #files

  for i, file in ipairs(files) do
    if i > MAX_FILES then
      local remain = total_files - MAX_FILES
      table.insert(lines, prefix .. "... " .. remain .. " files remains")
      break
    end

    table.insert(lines, prefix .. file)
  end
end

function M.open_tree()
  local buf = vim.api.nvim_create_buf(false, true)

  local cwd = vim.loop.cwd()
  local lines = { cwd }

  scan_dir(cwd, "", lines)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- buffer config
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  -- ===== floating window center =====
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.7)

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
  })

  vim.wo[win].number = false
  vim.wo[win].relativenumber = false

  -- close bằng q
  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf })
end

return M

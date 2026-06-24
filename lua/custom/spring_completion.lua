local group = vim.api.nvim_create_augroup("spring_boot_value_completion", { clear = true })

local function is_spring_config_file(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)

  return filename:match("/application[^/]*%.ya?ml$")
    or filename:match("/bootstrap[^/]*%.ya?ml$")
    or filename:match("/application[^/]*%.properties$")
    or filename:match("/bootstrap[^/]*%.properties$")
end

vim.api.nvim_create_autocmd("TextChangedI", {
  group = group,
  callback = function(args)
    if not is_spring_config_file(args.buf) then
      return
    end

    local spring_clients = vim.lsp.get_clients({
      bufnr = args.buf,
      name = "spring-boot",
    })

    if #spring_clients == 0 then
      return
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_get_current_line():sub(1, cursor[2])

    if not line:match(":%s+$") and not line:match("=%s*$") then
      return
    end

    local cmp = require "cmp"

    if not cmp.visible() then
      cmp.complete()
    end
  end,
})

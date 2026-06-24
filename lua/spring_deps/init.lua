local M = {}

local defaults = {
  base_url = "https://start.spring.io",
  keymaps = {
    add = "<leader>ja",
  },
}

local config = vim.deepcopy(defaults)

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, {
    title = "Spring Dependencies",
  })
end

local function apply(project, selections)
  if #selections == 0 then
    return
  end

  local result, err = require("spring_deps.editor").add(project, selections)
  if err then
    notify(err, vim.log.levels.ERROR)
    return
  end

  local messages = {}
  if #result.added > 0 then
    table.insert(messages, "Added: " .. table.concat(result.added, ", "))
  end
  if #result.skipped > 0 then
    table.insert(messages, "Already present: " .. table.concat(result.skipped, ", "))
  end
  notify(table.concat(messages, "\n"))
end

local function open_telescope(project, items)
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local conf = require("telescope.config").values
  local previewers = require "telescope.previewers"

  pickers.new({}, {
    prompt_title = "Spring Dependencies (" .. project.boot_version .. ")",
    finder = finders.new_table {
      results = items,
      entry_maker = function(item)
        local coordinate = item.coordinate.groupId .. ":" .. item.coordinate.artifactId
        return {
          value = item,
          ordinal = table.concat({ item.name, item.id, item.category, coordinate }, " "),
          display = string.format("%-32s  %s", item.name, item.category),
        }
      end,
    },
    sorter = conf.generic_sorter {},
    previewer = previewers.new_buffer_previewer {
      define_preview = function(self, entry)
        local item = entry.value
        local coordinate = item.coordinate.groupId .. ":" .. item.coordinate.artifactId
        local lines = {
          item.name,
          string.rep("=", #item.name),
          "",
          item.description or "No description",
          "",
          "Category: " .. item.category,
          "Initializr ID: " .. item.id,
          "Coordinate: " .. coordinate,
          "Scope: " .. (item.coordinate.scope or "compile"),
        }
        if item.bom_data then
          table.insert(lines, "BOM: " .. item.bom_data.groupId .. ":" .. item.bom_data.artifactId .. ":" .. item.bom_data.version)
        end
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.bo[self.state.bufnr].filetype = "markdown"
      end,
    },
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        if #selections == 0 then
          local selected = action_state.get_selected_entry()
          if selected then
            selections = { selected }
          end
        end

        actions.close(prompt_bufnr)
        apply(project, vim.tbl_map(function(entry)
          return entry.value
        end, selections))
      end)
      return true
    end,
  }):find()
end

function M.open()
  if vim.fn.executable "curl" ~= 1 then
    notify("curl is required", vim.log.levels.ERROR)
    return
  end

  local project = require("spring_deps.project").detect()
  if not project then
    notify("No pom.xml, build.gradle, or build.gradle.kts found", vim.log.levels.ERROR)
    return
  end
  if not project.boot_version then
    notify("Could not detect the Spring Boot version in " .. project.filename, vim.log.levels.ERROR)
    return
  end

  notify("Loading dependencies for Spring Boot " .. project.boot_version .. "...")
  require("spring_deps.client").fetch({
    base_url = config.base_url,
    boot_version = project.boot_version,
  }, function(result, err)
    if err then
      notify(err, vim.log.levels.ERROR)
      return
    end
    if #result.items == 0 then
      notify("No compatible dependencies returned by Spring Initializr", vim.log.levels.WARN)
      return
    end
    open_telescope(project, result.items)
  end)
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  vim.api.nvim_create_user_command("SpringDeps", M.open, {
    desc = "Search and add Spring Boot dependencies",
  })

  if config.keymaps.add then
    vim.keymap.set("n", config.keymaps.add, M.open, {
      desc = "Java add Spring dependency",
    })
  end
end

return M

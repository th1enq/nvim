local M = {}

local root_markers = {
  ".git",
  "mvnw",
  "gradlew",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "settings.gradle",
  "settings.gradle.kts",
}

function M.start()
  local jdtls = require "jdtls"
  local lspconfig = require "nvchad.configs.lspconfig"

  local root_dir = vim.fs.root(0, root_markers)
  if not root_dir then
    return
  end

  local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
  local workspace_dir = vim.fn.stdpath "data" .. "/jdtls-workspaces/" .. project_name
  local mason_dir = vim.fn.stdpath "data" .. "/mason"
  local jdtls_cmd = mason_dir .. "/bin/jdtls"
  local lombok_jar = mason_dir .. "/packages/jdtls/lombok.jar"
  local cmd = {
    jdtls_cmd,
    "--jvm-arg=-Djava.import.generatesMetadataFilesAtProjectRoot=false",
    "--jvm-arg=-Xmx4G",
    "-data",
    workspace_dir,
  }

  if vim.uv.fs_stat(lombok_jar) then
    table.insert(cmd, 2, "--jvm-arg=-javaagent:" .. lombok_jar)
  end

  jdtls.start_or_attach {
    cmd = cmd,
    root_dir = root_dir,
    capabilities = lspconfig.capabilities,
    on_init = lspconfig.on_init,
    init_options = {
      bundles = require("spring_boot").java_extensions(),
    },
    settings = {
      java = {
        autobuild = {
          enabled = true,
        },
        configuration = {
          updateBuildConfiguration = "automatic",
        },
        eclipse = {
          downloadSources = true,
        },
        format = {
          enabled = true,
          comments = { enabled = false },
          tabSize = 4,
        },
        import = {
          gradle = {
            annotationProcessing = {
              enabled = true,
            },
          },
        },
        jdt = {
          ls = {
            lombokSupport = {
              enabled = true,
            },
          },
        },
        maven = {
          downloadSources = true,
        },
        symbols = {
          includeGeneratedCode = true,
        },
      },
    },
  }
end

return M

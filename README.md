**This repo is supposed to be used as config by NvChad users!**

- The main nvchad repo (NvChad/NvChad) is used as a plugin by this repo.
- So you just import its modules , like `require "nvchad.options" , require "nvchad.mappings"`
- So you can delete the .git from this repo ( when you clone it locally ) or fork it :)

# Credits

1) Lazyvim starter https://github.com/LazyVim/starter as nvchad's starter was inspired by Lazyvim's . It made a lot of things easier!

## Spring Boot dependencies

Use `:SpringDeps` or `<leader>ja` from a Spring Boot project to search the
Spring Initializr catalog and add one or more dependencies.

- Supports `pom.xml`, `build.gradle`, and `build.gradle.kts`.
- Detects the Spring Boot version from the nearest build file.
- Press `<Tab>` in Telescope to select multiple dependencies, then `<Enter>`.
- Adds required BOM declarations and skips coordinates already in the file.

The plugin uses `https://start.spring.io` and requires `curl`. Configuration:

```lua
require("spring_deps").setup {
  base_url = "https://start.spring.io",
  keymaps = {
    add = "<leader>ja",
  },
}
```

Set `keymaps.add = false` to disable the default mapping.

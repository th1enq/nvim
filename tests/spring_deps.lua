local root = vim.fn.getcwd()
vim.opt.runtimepath:append(root)

local editor = require "spring_deps.editor"
local project = require "spring_deps.project"

local function fixture(content)
  local path = vim.fn.tempname()
  vim.fn.writefile(vim.split(content, "\n", { plain = true }), path)
  return path
end

local function content(path)
  return table.concat(vim.fn.readfile(path), "\n")
end

local data_jpa = {
  id = "data-jpa",
  name = "Spring Data JPA",
  coordinate = {
    groupId = "org.springframework.boot",
    artifactId = "spring-boot-starter-data-jpa",
    scope = "compile",
  },
}

local cloud_config = {
  id = "cloud-config-client",
  name = "Config Client",
  coordinate = {
    groupId = "org.springframework.cloud",
    artifactId = "spring-cloud-starter-config",
    scope = "compile",
    bom = "spring-cloud",
  },
  bom_data = {
    groupId = "org.springframework.cloud",
    artifactId = "spring-cloud-dependencies",
    version = "2025.0.3",
  },
}

local lombok = {
  id = "lombok",
  name = "Lombok",
  coordinate = {
    groupId = "org.projectlombok",
    artifactId = "lombok",
    scope = "annotationProcessor",
  },
}

local saml2 = {
  id = "security-saml2",
  name = "OAuth2 SAML2",
  coordinate = {
    groupId = "org.springframework.boot",
    artifactId = "spring-boot-starter-security-saml2",
    scope = "compile",
    repository = "shibboleth-releases",
  },
  repository_id = "shibboleth-releases",
  repository_data = {
    name = "Shibboleth Releases Repository",
    url = "https://build.shibboleth.net/maven/releases",
  },
}

do
  local path = fixture [[
<project>
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.5.15</version>
  </parent>
  <dependencies>
  </dependencies>
</project>]]
  local result = assert(editor.add({ path = path, kind = "maven" }, { data_jpa, cloud_config, saml2 }))
  local output = content(path)

  assert(#result.added == 3)
  assert(output:find("<artifactId>spring%-boot%-starter%-data%-jpa</artifactId>"))
  assert(output:find("<dependencyManagement>"))
  assert(output:find("<artifactId>spring%-cloud%-dependencies</artifactId>"))
  assert(output:find("<scope>import</scope>"))
  assert(output:find("<id>shibboleth%-releases</id>"))
  assert(output:find("https://build%.shibboleth%.net/maven/releases"))
  assert(project.maven_boot_version(output) == "3.5.15")

  local duplicate = assert(editor.add({ path = path, kind = "maven" }, { data_jpa }))
  assert(#duplicate.added == 0 and #duplicate.skipped == 1)
end

do
  local path = fixture [[
plugins {
  id 'java'
  id 'org.springframework.boot' version '3.5.15'
}

dependencies {
}]]
  assert(editor.add({ path = path, kind = "gradle", dsl = "groovy" }, { lombok, cloud_config, saml2 }))
  local output = content(path)

  assert(output:find("compileOnly 'org%.projectlombok:lombok'"))
  assert(output:find("annotationProcessor 'org%.projectlombok:lombok'"))
  assert(output:find("implementation platform%('org%.springframework%.cloud:spring%-cloud%-dependencies:2025%.0%.3'%)"))
  assert(output:find("maven { url = uri%('https://build%.shibboleth%.net/maven/releases'%) }"))
  assert(project.gradle_boot_version(output) == "3.5.15")
end

do
  local path = fixture [[
plugins {
  id("org.springframework.boot") version "3.5.15"
}

dependencies {
}]]
  assert(editor.add({ path = path, kind = "gradle", dsl = "kotlin" }, { data_jpa }))
  local output = content(path)

  assert(output:find('implementation%("org%.springframework%.boot:spring%-boot%-starter%-data%-jpa"%)'))
  assert(project.gradle_boot_version(output) == "3.5.15")
end

print "spring_deps tests passed"

package = "cosy-github"
version = "master-1"
source  = {
  url    = "git+https://github.com/cosyverif/github.git",
  branch = "master",
}

description = {
  summary    = "CosyVerif: github",
  detailed   = [[]],
  homepage   = "http://www.cosyverif.org/",
  license    = "MIT/X11",
  maintainer = "Alban Linard <alban@linard.fr>",
}

dependencies = {
  "lua >= 5.1",
  "lapis",
  "luaposix",
  "luasocket",
  "lua-cjson",
  "lua-resty-exec",
  "lua-resty-http",
  "lua-resty-qless", -- FIXME: remove rockspec, fix wercker.yml and Dockerfile
}

build = {
  type    = "builtin",
  modules = {
    ["config"                   ] = "config.lua",
    ["cosy.github"              ] = "src/cosy/github/init.lua",
    ["cosy.github.http"         ] = "src/cosy/github/http.lua",
    ["cosy.github.model"        ] = "src/cosy/github/model.lua",
    ["cosy.github.keys.job"     ] = "src/cosy/github/keys/job.lua",
    ["cosy.github.editors.clean"] = "src/cosy/github/editors/clean.lua",
    ["cosy.github.editors.start"] = "src/cosy/github/editors/start.lua",
  },
  install = {
    bin = {
      ["cosy"     ] = "src/cosy/github/bin.lua",
      ["cosy-keys"] = "src/cosy/github/keys/bin.lua",
    },
  },
}

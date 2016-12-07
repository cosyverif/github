package = "cosy-github-env"
version = "master-1"
source  = {
  url    = "git+https://github.com/cosyverif/github.git",
  branch = "master",
}

description = {
  summary    = "CosyVerif: github (dev dependencies)",
  detailed   = [[]],
  homepage   = "http://www.cosyverif.org/",
  license    = "MIT/X11",
  maintainer = "Alban Linard <alban@linard.fr>",
}

dependencies = {
  "lua >= 5.1",
  "busted",
  "cluacov",
  "cosy-instance",
  "luacheck",
  "luacov",
  "luacov-coveralls",
}

build = {
  type    = "builtin",
  modules = {},
}

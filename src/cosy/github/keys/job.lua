local Config = require "lapis.config".get ()
local Http   = require "cosy.github.http"
local Model  = require "cosy.github.model"
local Exec   = require "resty.exec"
local Json   = require "cjson"

local Job = {}

function Job.perform (job)
  local account = Model.accounts:find {
    id = job.data.id,
  }
  assert (account.token)
  local run    = Exec.new "/tmp/exec.sock"
  local result = assert (run "cosy-keys")
  assert (result.exitcode == 0)
  local keys   = Json.decode (result.stdout)
  assert (type (keys) == "table" and keys.public and keys.private)
  local _, status = Http {
    url     = "https://api.github.com/user/keys",
    method  = "POST",
    headers = {
      ["Accept"       ] = "application/vnd.github.v3+json",
      ["Authorization"] = "token " .. tostring (account.token),
      ["User-Agent"   ] = Config.gh_app_name,
    },
    body    = {
      title = Config.gh_app_name,
      key   = keys.public,
    },
  }
  assert (status == 201, status)
  account:update {
    public  = keys.public,
    private = keys.private,
  }
  return true
end

return Job

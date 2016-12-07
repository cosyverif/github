local Et     = require "etlua"
local Lapis  = require "lapis"
local Util   = require "lapis.util"
local Config = require "lapis.config".get ()
local Http   = require "cosy.github.http"
local Model  = require "cosy.github.model"
local Qless  = require "resty.qless"

local app    = Lapis.Application ()
app:enable "etlua"
app.layout = false

app.handle_error = function (_, error, trace)
  print (error)
  print (trace)
  return { status = 500 }
end

app.handle_404 = function ()
  return { status = 404 }
end

local function check_scopes (account)
  local _, status, headers = Http {
    url     = "https://api.github.com/user",
    method  = "GET",
    headers = {
      ["Accept"       ] = "application/vnd.github.v3+json",
      ["Authorization"] = "token " .. tostring (account.token),
      ["User-Agent"   ] = Config.gh_app_name,
    },
  }
  assert (status == 200, status)
  local header = assert (headers ["X-OAuth-Scopes"])
  local scopes = {}
  for scope in header:gmatch "[^,%s]+" do
    scopes [scope] = true
  end
  return scopes ["write:public_key"] ~= nil
     and scopes ["user:email"      ] ~= nil
end

app:match ("/", function (self)
  local ok, account = pcall (function ()
    local account = Model.accounts:find {
      id = assert (self.session.gh_id),
    }
    assert (check_scopes (account))
    return account
  end)
  if ok then
    self.user = {
      id    = account.id,
      token = account.token,
    }
    return {
      status = 200,
      render = "main",
      layout = "layout",
    }
  else
    return {
      redirect_to = Et.render ("https://github.com/login/oauth/authorize?state=<%- state %>&scope=<%- scope %>&client_id=<%- client_id %>", {
        client_id = Config.gh_client_id,
        state     = Config.gh_oauth_state,
        scope     = Util.escape "user:email write:public_key",
      })
    }
  end
end)

app:match ("/newuser", function (self)
  if self.params.state ~= Config.gh_oauth_state then
    return { status = 400 }
  end
  local result, status, headers
  result, status = Http {
    url     = "https://github.com/login/oauth/access_token",
    method  = "POST",
    headers = {
      ["Accept"] = "application/vnd.github.v3+json",
    },
    body    = {
      client_id     = Config.gh_client_id,
      client_secret = Config.gh_client_secret,
      state         = Config.gh_oauth_state,
      code          = self.params.code,
    },
  }
  assert (status == 200, status)
  local token = result.access_token
  result, status, headers = Http {
    url     = "https://api.github.com/user",
    method  = "GET",
    headers = {
      ["Accept"       ] = "application/vnd.github.v3+json",
      ["Authorization"] = "token " .. tostring (token),
      ["User-Agent"   ] = Config.gh_app_name,
    },
  }
  assert (status == 200, status)
  local account = Model.accounts:find {
    id = result.id
  }
  if account then
    account:update {
      token = token,
    }
  else
    account = Model.accounts:create {
      id    = result.id,
      token = token,
    }
  end
  self.session.gh_id    = account.id
  self.session.gh_token = account.token
  local header = assert (headers ["X-OAuth-Scopes"])
  local scopes = {}
  for scope in header:gmatch "[^,%s]+" do
    scopes [scope] = true
  end
  if not scopes ["user:email"]
  or not scopes ["write:public_key"] then
    return { status = 401 }
  end
  if not account.public
  or not account.private then
    local qless = Qless.new (Config.redis)
    local queue = qless.queues ["cosy"]
    queue:put ("cosy.github.keys.job", {
      id = account.id,
    }, {
      jid = "keys-" .. tostring (account.id),
    })
  end
  return { redirect_to = "/" }
end)

return app

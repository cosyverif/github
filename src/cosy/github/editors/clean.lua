local Config   = require "lapis.config".get ()
local Database = require "lapis.db"
local Model    = require "cosy.github.model"
local Http     = require "cosy.github.http"
local Mime     = require "mime"

local Clean = {}

function Clean.perform ()
  local editors = Model.editors:select [[ where docker is not null and starting = false ]]
  for _, editor in ipairs (editors or {}) do
    local info, status = Http {
      url     = editor.docker,
      method  = "GET",
      headers = {
        ["Authorization"] = "Basic " .. Mime.b64 (Config.docker.username .. ":" .. Config.docker.api_key),
      },
    }
    if (status == 200 and info.state:lower () ~= "starting" and info.state:lower () ~= "running")
    or  status == 404 then
      editor:update {
        url = Database.NULL,
      }
    end
    if not editor.url then
      _, status = Http {
        url     = editor.docker,
        method  = "DELETE",
        headers = {
          ["Authorization"] = "Basic " .. Mime.b64 (Config.docker.username .. ":" .. Config.docker.api_key),
        },
      }
      if (status >= 200 and status < 300) or status == 404 then
        editor:delete ()
      end
    end
  end
end

return Clean

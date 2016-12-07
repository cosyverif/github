local Config   = require "lapis.config".get ()
local Model    = require "cosy.github.model"
local Http     = require "cosy.github.http"
local Et       = require "etlua"
local Mime     = require "mime"
local Json     = require "cjson"
local gettime  = require "socket".gettime

local Start = {}

function Start.perform (job)
  local editor = Model.editors:create {
    id       = job.data.id,
    starting = true,
  }
  if not editor then
    return
  end
  local url     = "https://cloud.docker.com"
  local api     = url .. "/api/app/v1/cosyverif"
  local headers = {
    ["Authorization"] = "Basic " .. Mime.b64 (Config.docker.username .. ":" .. Config.docker.api_key),
  }
  -- Get API url:
  pcall (function ()
    local server_url
    local api_url = os.getenv "DOCKERCLOUD_SERVICE_API_URL" or ""
    if api_url ~= "" then
      local service_info, service_status = Http {
        url     = api_url,
        method  = "GET",
        headers = headers,
      }
      assert (service_status == 200, service_status)
      local container_info, container_status = Http {
        url     = url .. service_info.containers [1],
        method  = "GET",
        headers = headers,
      }
      assert (container_status == 200, container_status)
      for _, port in ipairs (container_info.container_ports) do
        local endpoint = port.endpoint_uri
        if endpoint and endpoint ~= Json.null then
          if endpoint:sub (-1) == "/" then
            endpoint = endpoint:sub (1, #endpoint-1)
          end
          server_url = endpoint
          break
        end
      end
    else
      server_url = "http://localhost:8080"
    end
    assert (server_url, server_url)
    -- Create service:
    local data = {
      -- FIXME
    }
    local arguments = {}
    for key, value in pairs (data) do
      arguments [#arguments+1] = Et.render ("--<%- key %>=<%- value %>", {
        key   = key,
        value = value,
      })
    end
    local service, service_status = Http {
      url     = api .. "/service/",
      method  = "POST",
      headers = headers,
      body    = {
        image           = "cosyverif/editor:dev",
        run_command     = table.concat (arguments, " "),
        autorestart     = "OFF",
        autodestroy     = "ALWAYS",
        autoredeploy    = false,
        container_ports = {
          { protocol   = "tcp",
            inner_port = 8080,
            published  = true,
          },
        },
      },
    }
    assert (service_status == 201, service_status)
    -- Editor service:
    service = url .. service.resource_uri
    editor:update {
      docker = service,
    }
    local _, started_status = Http {
      url     = service .. "start/",
      method  = "POST",
      headers = headers,
      timeout = 10, -- seconds
    }
    assert (started_status == 202, started_status)
    local start = gettime ()
    while gettime () - start <= 120 do
      job:heartbeat()
      local result, status = Http {
        url     = service,
        method  = "GET",
        headers = headers,
      }
      assert (status == 200, status)
      if status == 200 and result.state:lower () ~= "starting" then
        local container, container_status = Http {
          url     = url .. result.containers [1],
          method  = "GET",
          headers = headers,
        }
        assert (container_status == 200, container_status)
        for _, port in ipairs (container.container_ports) do
          local endpoint = port.endpoint_uri
          if endpoint and endpoint ~= Json.null then
            if endpoint:sub (-1) == "/" then
              endpoint = endpoint:sub (1, #endpoint-1)
            end
            editor:update {
              url = endpoint,
            }
            return
          end
        end
      else
        _G.ngx.sleep (1)
      end
    end
  end)
  editor:update {
    starting = false,
  }
  return true
end

return Start

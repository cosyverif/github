local Http = require "resty.http"
local Json = require "cjson"
local Util = require "lapis.util"

return function (options)
  assert (type (options) == "table")
  options.ssl_verify = false
  options.method     = options.method  or "GET"
  options.body       = options.body    and Json.encode (options.body)
  options.headers    = options.headers or {}
  local query        = {}
  for k, v in pairs (options.query or {}) do
    query [#query+1] = Util.encode (k) .. "=" .. Util.encode (v)
  end
  options.query      = table.concat (query, "&")
  options.headers ["Content-length"] = options.body and #options.body
  options.headers ["Content-type"  ] = options.body and "application/json"
  options.headers ["Accept"        ] = "application/json"
  local client = Http.new ()
  client:set_timeout ((options.timeout or 5) * 1000) -- milliseconds
  local result = assert (client:request_uri (options.url, options))
  if result.body then
    local ok, json = pcall (Json.decode, result.body)
    if ok then
      result.body = json
    end
  end
  return result.body, result.status, result.headers
end

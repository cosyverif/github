local Model  = require "lapis.db.model".Model
local result = {}

result.accounts = Model:extend ("accounts", {})
result.editors  = Model:extend ("editors" , {})

return result

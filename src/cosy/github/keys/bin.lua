#! /usr/bin/env lua

local Et       = require "etlua"
local Json     = require "cjson"
local filename = os.tmpname ()

os.remove (filename)
local done = os.execute (Et.render ([[ ssh-keygen -q -t rsa -b 4096 -f <%- filename %> -N "" ]], {
  filename = filename,
}))

local private, public, file
if done then
  pcall (function ()
    file    = assert (io.open (filename, "r"))
    private = file:read "*a"
    file:close ()
    file    = assert (io.open (filename .. ".pub", "r"))
    public  = file:read "*l"
    file:close ()
  end)
end

if private and public then
  print (Json.encode {
    private = private,
    public  = public,
  })
end

os.execute (Et.render ([[ rm -rf <%- filename %> <%- filename %>.pub ]], {
  filename = filename,
}))

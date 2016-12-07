local Schema = require "lapis.db.schema"

return {
  function ()
    Schema.create_table ("accounts", {
      { "id"     , Schema.types.integer { primary_key = true } },
      { "token"  , Schema.types.text    { null        = true } },
      { "public" , Schema.types.text    { null        = true } },
      { "private", Schema.types.text    { null        = true } },
    })
  end,
}

local typedefs = require "kong.db.schema.typedefs"
local PLUGIN_NAME = "jwt-to-headers"

local schema = {
  name = PLUGIN_NAME,
  fields = {
    -- the 'fields' array is the top-level entry with fields defined by Kong
    { consumer = typedefs.no_consumer }, -- this plugin cannot be configured on a consumer (typical for auth plugins)
    { protocols = typedefs.protocols_http },
    {
      config = {
        -- The 'config' record is the custom part of the plugin schema
        type = "record",
        fields = {
          {
            jwt_type = {
              type = "string",
              default = "cookie",
              one_of = { "header", "cookie" },
              required = true
            }
          },
          {
            jwt_location_name = { -- field name in which the jwt is stored
              type = "string",
              required = true
            }
          },
          {
            jwt_into_body = { -- the header name in which the jwt body in injected
              type = "string",
              default = "x-userinfo",
              required = false
            }
          },
          {
            jwt_into_header = { -- the header name in which the full jwt is injected
              type = "string",  -- valid only if jwt_type is cookie
              default = "authorization",
              required = false
            }
          },
          {
            jwt_fields_into_headers = { -- hashmap that map a field name (jwt) into an header
              type = "map",
              keys = { type = "string" },
              values = { type = "string" },
              required = false
            }
          },
          {
            jwt_header_to_clear = { -- if set then clear headers at execution beginning
              type = "array",
              elements = { type = "string" },
              required = false
            }
          }
        },
        entity_checks = {}
      },
    },
  },
}

return schema

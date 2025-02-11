local plugin = {
  PRIORITY = 950, --1450 is the jwt execution priority, 1000 is the kong-oidc plugin. Lower priority == later execution
  VERSION = "1.0.0"
}

-- local base64 decode implementation
-- no ext lib needed
local function base64_decode(data)
  local charSet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

  data = string.gsub(data, '[^' .. charSet .. '=]', '')
  return (data:gsub('.', function(x)
    if x == '=' then return '' end
    local r, f = '', (charSet:find(x) - 1)
    for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
    return r
  end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if #x < 8 then return '' end
    local c = 0
    for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
    return string.char(c)
  end))
end

-- set jwt body fields into headers
-- example preferred_username into x-credential-identifier
local function set_jwt_fields_into_headers(plugin_conf, body)
  if plugin_conf.jwt_fields_into_headers then
    local cjson = require "cjson"
    -- read jwt
    local decodedJwt = base64_decode(body)
    local payload = cjson.decode(decodedJwt)

    if not payload then
      kong.log.err("Invalid JWT token payload")
      return
    end

    for k, v in pairs(plugin_conf.jwt_fields_into_headers) do
      if payload[k] then
        kong.service.request.set_header(v, payload[k])
      end
    end
  end
end

-- set jwt body into a pre defined header if configured
local function set_jwt_body_into_header(plugin_conf, body)
  if plugin_conf.jwt_into_body then
    kong.service.request.set_header(plugin_conf.jwt_into_body, body)
  end
end

-- set full jwt token into header if cookie is used
-- return jwtValue
local function set_jwt_full_into_header(plugin_conf)
  local jwtValue
  local restyCookie = require "resty.cookie"
  if string.lower(plugin_conf.jwt_type) == "cookie" then
    local ck = restyCookie:new()
    jwtValue = ck:get(plugin_conf.jwt_location_name)

    if not jwtValue then
      kong.log.err("Jwt token not found")
      return
    end

    if plugin_conf.jwt_into_header then
      if string.lower(plugin_conf.jwt_into_header) == "authorization" then
        kong.service.request.set_header("Authorization", "Bearer " .. jwtValue)
      else
        kong.service.request.set_header(plugin_conf.jwt_into_header, jwtValue)
      end
    end
  else
    jwtValue = kong.request.get_header(plugin_conf.jwt_location_name)
    if not jwtValue then
      -- in this case no jwt is provided
      -- no errors required
      return
    end
    if string.lower(plugin_conf.jwt_location_name) == "authorization" then
      jwtValue = string.sub(jwtValue, 8) -- strip "bearer "
    end
  end

  return jwtValue
end

-- clear http request headers
local function clear_headers(plugin_conf)
  if plugin_conf.jwt_header_to_clear then
    for _, value in ipairs(plugin_conf.jwt_header_to_clear)
    do
      kong.service.request.clear_header(value)
    end
  end
end

-- runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)
  -- clear headers if configured
  clear_headers(plugin_conf)
  -- kong.log.notice("Clear headers done")

  -- precheck
  if not plugin_conf.jwt_type or not plugin_conf.jwt_location_name then
    kong.log.err("Jwt Type and Jwt Location Name are mandatory")
    return
  end
  -- kong.log.notice("Precheck passed")

  local jwtValue = set_jwt_full_into_header(plugin_conf)
  if not jwtValue then
    kong.log.err("Jwt token not found")
    return
  end
  -- kong.log.notice("Jwt full into header")

  -- split jwtValue into array dot separated [1][2][3]
  local jwtParts = {}
  for part in string.gmatch(jwtValue, "([^%.]+)") do
    table.insert(jwtParts, part)
  end

  if not jwtParts[2] then
    kong.log.err("Invalid token body")
    return
  end
  -- kong.log.notice("Token splitted")

  -- jwt into body
  set_jwt_body_into_header(plugin_conf, jwtParts[2])
  -- kong.log.notice("Jwt body into header done")

  -- jwt body fields into headers
  set_jwt_fields_into_headers(plugin_conf, jwtParts[2])
  -- kong.log.notice("Jwt fields into headers done")
end

-- return our plugin object
return plugin

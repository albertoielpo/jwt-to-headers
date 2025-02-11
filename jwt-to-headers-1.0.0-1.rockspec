package = "jwt-to-headers"
version = "1.0.0-1"
source = {
    url = "https://github.com/albertoielpo/jwt-to-headers.git",
    tag = "main",
    dir = "jwt-to-headers"
}
description = {
    summary = "Convert a jwt token into headers",
    detailed = [[
          It takes a jwt token that can be place inside a cookie or an header and generate programmatically http headers
    ]],
    homepage = "https://github.com/albertoielpo/jwt-to-headers.git",
    license = "MIT"
}
dependencies = {
    "lua-resty-cookie ~> 0.1.0"
}
build = {
    type = "builtin",
    modules = {
    ["kong.plugins.jwt-to-headers.handler"] = "kong/plugins/jwt-to-headers/handler.lua",
    ["kong.plugins.jwt-to-headers.schema"] = "kong/plugins/jwt-to-headers/schema.lua",
    }
}

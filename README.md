# Jwt to headers
Convert a jwt token into headers

It takes a jwt token that can be place inside a cookie or an header and generate programmatically http headers

<b>IMPORTANT</b>: no validation checks are provided!

The aim of this plugin is to work in combination with kong jwt plugin <link>https://docs.konghq.com/hub/kong-inc/jwt/</link>.

## Execution priority
- kong jwt (1450)
- jwt to headers (950)

## How to use
A configuration example for:
- jwt token inside a cookie named <code>token</code>
- jwt full token is inserted into the <code>authorization</code> header
- jwt body is inserted into <code>x-jwt-body</code> header
- jwt body fields <code> field1 </code> and <code>field2</code> are mapped respectively to <code>x-field1</code> and <code>x-field2</code> headers
- the headers <code>x-field1</code> and <code>x-field2</code> are cleared at the execution beginning. This property is useful to avoid data tampering to sensitive data.

```yaml
plugins:
  - config:
      jwt_fields_into_headers:
        field1: x-field1
        field2: x-field2
      jwt_header_to_clear:
        - x-field1
        - x-field2
      jwt_into_body: x-jwt-body
      jwt_into_header: authorization
      jwt_location_name: token
      jwt_type: cookie
    enabled: true
    name: jwt-to-headers
    protocols:
      - http
      - https
```

## Configuration
Check <code>schema.lua</code> to see which fields are mandatory and which can be omitted

## Authors
- Alberto Ielpo <alberto.ielpo@gmail.com>
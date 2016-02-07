local http = require 'http_server'
local utils = require 'utils'
local driver = require 'car_driver'

local function request_parser_test()
    local example_payload =
    [[POST /move HTTP/1.1
    Host: 10.0.0.7
    Cache-Control: no-cache
    Postman-Token: 77305d3d-7f00-9474-cd96-fa7df113b841

    {"acceleration": 200, "steering":30}]]

    local request = http.testctx.parse_request(example_payload)
    --print(cjson.encode(request))
    --utils.print_table(request)
    assert(request.method == 'POST')
    assert(request.url == '/move')
    assert(utils.deep_compare(request.params, {}))

    headers = {}
    headers['Host'] = '10.0.0.7'
    headers["Cache-Control"] = 'no-cache'
    headers["Postman-Token"] = '77305d3d-7f00-9474-cd96-fa7df113b841'

    assert(utils.deep_compare(request.headers, headers))
    assert(request.body == '{"acceleration": 200, "steering":30}')
end

request_parser_test()

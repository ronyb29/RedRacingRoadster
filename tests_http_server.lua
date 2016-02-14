local http = require 'http_server'
local utils = require 'utils'
local driver = require 'car_driver'

local function request_parser_test()
    local example_payload = [[POST /move HTTP/1.1
Host: 10.0.0.7
Cache-Control: no-cache
Postman-Token: 77305d3d-7f00-9474-cd96-fa7df113b841

{"acceleration": 200, "steering":30}]]

    local request = http.testctx.parse_request(example_payload)
    assert(request.method == 'POST')
    assert(request.url == '/move')
    assert(utils.deep_compare(request.params, {}))

    local headers = {}
    headers['Host'] = '10.0.0.7'
    headers["Cache-Control"] = 'no-cache'
    headers["Postman-Token"] = '77305d3d-7f00-9474-cd96-fa7df113b841'

    assert(utils.deep_compare(request.headers, headers))
    assert(request.body == '{"acceleration": 200, "steering":30}')
end

request_parser_test()



local function header_renderer_test()
    local request = {
        code = 404,
        body = 'Hola me llamo rony',
        headers = { ['x-rony'] = 'es gordito' }
    }
    local expected_header = "HTTP/1.1 404 Not Found" .. http.EOL .. 'Content-Lenght: 18' .. http.EOL .. 'x-rony: es gordito' .. http.EOL .. http.EOL
    local actual_header = http.testctx.render_header(request)
    assert(actual_header == expected_header)
end

header_renderer_test()


local function router_test()
    local routes = {
        ['index.html'] = {
            ['GET'] = "Correct!",
            ['HEAD'] = "Correct!"
        }
    }

    print(http.testctx.solve_route(routes, 'index.html', 'GET'))
    print(http.testctx.solve_route(routes, 'index.html', 'HEAD'))
    print(http.testctx.solve_route(routes, 'index.html', 'PUT'))
end

router_test()
-- A simple http server written for my RedRacingRoadster
-- Author: Rony L. Batista <rony.batista29@gmail.com>
-- at: github.com/ronyb29/RedRacingRoadster

-- request context should contain
-- * Parsed request url, url params, method, headers and body
-- * methods or variables for setting response Headers, code and body
-- * a response.send method
-- * Underlying connection

-- the web server must provide
-- * a way to register routes
-- * a way to stop

--Route handlers (callbacks) must comply to the F(request, response) signature, where it will set the response data
local utils = require 'utils'
local EOL = '\r\n'
local http_status_codes = {
    [200] = 'OK',
    ["200"] = 'OK',
    [201] = 'Created',
    [202] = 'Accepted',
    [301] = 'Moved Permanently',
    [302] = 'Found',
    [304] = 'Not Modified',
    [307] = 'Temporary Redirect',
    [308] = 'Permanent Redirect',
    [400] = 'Bad Request',
    [401] = 'Unauthorized',
    [403] = 'Forbidden',
    [404] = 'Not Found',
    [405] = 'Method Not Allowed',
    [406] = 'Not Acceptable',
    [500] = 'Internal Server Error',
    [501] = 'Not Implemented',
    [520] = 'Unknown Error'
}


local function serve_file(filename)
    return function(request, response)

        local sent, buffer_size = 0, 0
        local function serve_file_sending_cb(sock)
            sent = sent + buffer_size

            file.open(filename, 'r')
            file.seek('set', sent)

            local content = file.read(1024)
            file.close()

            buffer_size = #content
            if buffer_size == 1024 then
                sock:send(content, serve_file_sending_cb)
            else
                sock:send(content, sock.close)
            end
        end

        response.headers['Content-Lenght'] = file.list()[filename]
        response.code = 200
        response.sock:send(response:render_header(), serve_file_sending_cb)
        return nil
    end
end


local function parse_params(raw_params)
    --todo: optimize Regex
    local response = {}
    for kvp in string.gmatch(raw_params, "[^&]+") do
        for k, v in string.gmatch(kvp, '(%S+)=(%S+)') do
            response[k] = v
        end
    end

    if #response then
        return response
    else
        return nil
    end
end

local function parse_headers(raw_headers)
    --todo: optimize Regex
    local response = {}
    for kvp in string.gmatch(raw_headers, "[^\n\r]+") do
        for k, v in string.gmatch(kvp, '(%S+): ([%S ]+)') do
            response[k] = v
        end
    end
    return response
end

local function parse_request(payload)
    local request, raw_params, raw_headers = {}, nil, nil
    request.method, request.url, raw_params, request.http_ver, raw_headers, request.body = string.match(payload, '(%S*) (/[%l%u.]*)%??(%S*) (%S*)[\r\n]([%S* \r\n]+)[\r\n][\r\n](.*)')
    request.params = parse_params(raw_params)
    request.headers = parse_headers(raw_headers)
    return request
end

local function render_header(response)
    local code = response.code or 200
    local message = response.message or http_status_codes[response.code]
    message = message or 'unknown code'
    local raw_response = (response.http_ver or 'HTTP/1.1') .. ' ' .. code .. ' ' .. message .. EOL
    if response.body then
        response.headers['Content-Lenght'] = response.headers['Content-Lenght'] or #response.body
    end
    if response.headers then
        for k, v in pairs(response.headers) do
            raw_response = raw_response .. k .. ': ' .. tostring(v) .. EOL
        end
    end
    return raw_response .. EOL
end

local function send_response(response)
    response.sock:send(response:render_header() .. response.body, function(conn) conn:close() end)
end

local function solve_route(routes, url, method)
    local routed_function
    if routes[url] then
        if routes[url][method] then
            routed_function = routes[url][method]
        else
            return function(request, response) response.code = 405 end
        end
    else
        local file_name = string.match(url, '/(%S+)')
        if file.list()[file_name] then
            routed_function = serve_file(file_name)
        end
    end
    return routed_function
end

local function http_server_cb(routes)
    return function(conn)
        conn:on('receive', function(conn, payload)
            if node.heap() < 10000 then
                conn:close()
                return
            end

            local request = parse_request(payload)
            payload = nil --free the original payload after parsing
            print(request.method, request.url, node.heap())

            if request.url == '/' then
                request.url = '/index.html'
            end

            local response = { send = send_response, render_header = render_header, http_ver = request.http_ver, code = nil, message = nil, headers = {}, body = nil, sock = conn }
            local routed_function = solve_route(routes, request.url, request.method)

            if not routed_function then
                response.code, response.body = 404, 'Resource "' .. request.url .. '" Not Found'
                response:send()
                return
            end

            local successful, retval = pcall(routed_function, request, response)
            if not successful then
                response.code = 520
            end

            if retval then
                response.body = response.body or retval
                response:send()
            end
        end)
    end
end

local function add_route(server, url, method, callback)
    if not (server.routes[url]) then
        server.routes[url] = {}
    end
    server.routes[url][method] = callback
end

local function create_server(port)
    local routes = {}
    local srv = net.createServer(net.TCP)

    local function start()
        srv:listen(port, http_server_cb(routes))
    end

    return { server = srv, add_route = add_route, start = start, routes = routes }
end


return {
    create_server = create_server,
    serve_file = serve_file,
    EOL = EOL,
    testctx = {
        parse_params = parse_params,
        parse_headers = parse_headers,
        parse_request = parse_request,
        render_header = render_header,
        solve_route = solve_route
    }
}

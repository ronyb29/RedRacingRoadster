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
local EOL = '\r\n'
local http_status_codes = {
    [200] = 'OK',
    [201] = 'Created',
    [202] = 'Accepted',
    [204] = 'No Content',
    [205] = 'Reset Content',
    [301] = 'Moved Permanently',
    [302] = 'Found',
    [303] = 'See Other',
    [304] = 'Not Modified',
    [305] = 'Use Proxy',
    [307] = 'Temporary Redirect',
    [308] = 'Permanent Redirect',
    [400] = 'Bad Request',
    [401] = 'Unauthorized',
    [403] = 'Forbidden',
    [404] = 'Not Found',
    [405] = 'Method Not Allowed',
    [406] = 'Not Acceptable',
    [429] = 'Too Many Requests',
    [500] = 'Internal Server Error',
    [501] = 'Not Implemented',
    [503] = 'Service Unavailable',
    [504] = 'Gateway Timeout',
    [507] = 'Insufficient Storage',
    [520] = 'Unknown Error'
}

local function current_file_size()
    local current = file.seek('cur', 0)
    local size = file.seek('end', 0)
    file.seek('set', current)
    return size
end

local function serve_file(filename)
    --TODO: manage concurrency
    return function(request, response)
        print('opening file', filename)
        local rv = file.open(filename, 'r')
        if not rv then
            conn:send('HTTP/1.0 404 Not Found\r\n\r\n')
            return
        end

        print('reading', filename)
        local function sent_cb(connection)
            local content = file.read(1024)
            print('read: ', #content)
            if #content == 1024 then
                print('read: ', #content)
                connection:send(content, sent_cb)
            else
                connection:send(content,
                    function(conne)
                        file:close()
                        print('file closed')
                        conne:close()
                        print('conn closed')
                    end)
            end
        end

        response.sock:send('HTTP/1.0 200 OK\r\nContent-Length: ' .. current_file_size() .. '\r\n\r\n', sent_cb)

        print('file queued:' .. filename)
        return nil
    end
end


local function parse_params(raw_params)
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
    request.method, request.url, raw_params, request.http_ver, raw_headers, request.body = string.match(payload, '(%S*) (/[%l%u]*)%??(%S*) (%S*)[\r\n]([%S* \r\n]+)[\r\n][\r\n](.*)')
    request.params = parse_params(raw_params)
    request.headers = parse_headers(raw_headers)

    return request
end


local function send_response(response)
    response.headers['Content-Lenght'] = response.headers['Content-Lenght'] or #response.body
    --response.headers['Access-Control-Allow-Origin'] = response.headers['Access-Control-Allow-Origin'] or '*'
    local raw_response = response.http_ver .. ' ' .. response.code .. ' ' .. response.message .. EOL
    for k, v in pairs(response.headers) do
        raw_response = raw_response .. k .. tostring(v) .. EOL
    end

    response.sock:send(raw_response .. EOL .. response.body, function(conn) conn:close() end)
end

local function http_server_cb(routes)
    return function(conn)
        conn:on('receive', function(conn, payload)
            --print('Payload:', #payload, 'mem', node.heap())
            if node.heap() < 10000 then
                conn:close()
                return
            end

            local request = parse_request(payload)
            payload = nil --free the original payload after parsing

            if request.url == '/' then
                request.url = '/index.html'
            end

            local response = { http_ver = request.http_ver, code = nil, message = nil, headers = {}, body = nil, sock = conn, send = send_response }
            --response.code, response.message, response.body = 404, 'not found', 'not found'
            --print(request.url, request.method)
            --TODO: if no route is found, redirect to static file
            local retval = routes[request.url][request.method](request, response)

            if retval then
                response.code = response.code or 200
                response.message = response.message or http_status_codes[response.code] or 'Uknown code'
                response.body = response.body or retval
                send_response(response)
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
    testctx = {
        parse_request = parse_request
    }
}

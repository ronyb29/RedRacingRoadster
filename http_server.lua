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
local EOL = '\n\r'

local function current_file_size()
    local current = file.seek('cur',0)
    local size = file.seek('end',0)
    file.seek('set',current)
    return size
end

local function serve_file(filename)
  --TODO: manage concurrency
  return function(request, response)
    print ('opening file', filename)
    local rv = file.open(filename, 'r')
    if not rv then
        conn:send('HTTP/1.0 404 Not Found\r\n\r\n')
        return
    end

    print('reading', filename)
    local function sent_cb(connection)
        local content = file.read(1024)
        print('read: ', #content)
        if #content==1024 then
            print('read: ', #content)
            connection:send(content, sent_cb)
        else
            connection:send(content,
                function (conne)
                    file:close()
                    print('file closed')
                    conne:close()
                    print('conn closed')
                    response['sock'] = nil
                end)
        end
    end

    response.sock:send('HTTP/1.0 200 OK\r\nContent-Length: ' .. current_file_size() ..'\r\n\r\n',               sent_cb)

    print ('file queued:' .. filename)
  end
end


local function parse_params(raw_params)
  local response = {}
  for kvp in string.gmatch(raw_params, "[^&]+") do
      for k,v in string.gmatch(kvp, '(%S+)=(%S+)') do
          response[k] = v
      end
  end
  return response
end

local function parse_headers(raw_headers)
  local response = {}
  --TODO: implement
  for kvp in string.gmatch(raw_headers, "[^\n\r]+") do
    for k,v in string.gmatch(kvp, '(%S+): ([%S ]+)') do
        response[k] = v
    end
  end
  return response
end

local function send_response(response)
  --TODO: add content-lenght header
  local raw_response = response['code'] .. response['message'] .. EOL
  for k,v in response['headers'] do
    raw_response = raw_response .. k .. tostring(v) .. EOL
  end

  response['sock']:send(raw_response .. EOL .. response['body'])
end

local function parse_request(payload)
    local request, raw_params, raw_headers = {}, nil, nil
    request.method, request.url, raw_params, request.http_ver, raw_headers = string.match(payload,'(%S*) (/[%l%u]*)%??(%S*) (%S*)[\r\n]([%S \n\r]*)')
    request.params = parse_params(raw_params)
    request.headers = parse_headers(raw_headers)
    
    return request
end

local function http_server(routes)
  return function (conn)
    conn:on('receive', function(conn, payload)
      print('Payload:', #payload, 'mem', node.heap())
      if node.heap() < 10000 then
          conn:close()
          return
      end

      local request = parse_request(payload)
      payload=nil --free the original payload after parsing

      if url == '/' then
        url = '/index.html'
      end
      --TODO: if no route is found, redirect to static file
      local response={code=nil, message = nil, headers = {}, body = nil, sock = conn}
      local code = routes[request['url']][request['method']](request, response)
      if(not response['code']) then
        response['code'] = code
      end
      send_response(response)
    end)
  end
end


local function create_server(port)
  local routes={}
  local function add_route(url, method, callback)
    if not (routes[url]) then
      routes[url] = {}
    end
    routes[url][method] = callback
  end


  local srv=net.createServer(net.TCP)
  local function start ()
    srv:listen(port, http_server(routes))
  end

  return {server = srv, add_route = add_route, start=start, routes=routes}
end


return {
    create_server = create_server, 
    serve_file=serve_file, 
    testctx={
            parse_request=parse_request
        }
    }

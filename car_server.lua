local driver = require 'car_driver'
local http = require 'http_server'

local errstr = "request must contain acceleration and steering params in json body"
local function move_car_controller(request, response)
    if not request.body then
        response.code = 400
        return errstr
    end

    local params = cjson.decode(request.body)
    local s, a = params.steering, params.acceleration

    if not (s and a) then
        response.code = 400
        return errstr
    end

    if s > 127 or s < -127 or a > 127 or a < -127 then
        response.code = 400
        return 'both parameters must be in the range  [-127,127]'
    end

    driver.move_car(s, a)
    return 'Free mem: ' .. tostring(node.heap())
end


local PORT = 80
local srv = http.create_server(PORT)
srv:add_route('/move', 'POST', move_car_controller)
srv:add_route('/move', 'PUT', move_car_controller)
srv:add_route('/index.html', 'GET', http.serve_file('index.html'))
srv:add_route('/favicon.ico', 'GET', http.serve_file('ffff'))

srv:start()

print('Server started on port', PORT)
print('http://' .. wifi.sta.getip() .. ':' .. tostring(PORT) .. '/') 

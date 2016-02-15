local driver = require 'car_driver'
local http = require 'http_server'
local PORT, REFRESH_INTERVAL, DEADZONE = 80, 500, 15


local errstr = "request must contain acceleration and steering params in json body"
local next_position = { acceleration = 0, steering = 0 }
local function move_car_controller(request, response)
    if not request.body then
        response.code = 400
        return errstr
    end

    local params = cjson.decode(request.body)
    if not (params.steering and params.acceleration) then
        response.code = 400
        return errstr
    end

    if params.steering > 127 or params.steering < -127 or params.acceleration > 127 or params.acceleration < -127 then
        response.code = 400
        return 'both parameters must be in the range  [-127,127]'
    end
    next_position = params

    return 'Free mem: ' .. tostring(node.heap())
end

local last_val = { acceleration = 0, steering = 0 }
local function apply_movement_timer_cb()
    --changes the position only if an increment of more than 15 has occoure
    local dsteer = math.abs(last_val.steering - next_position.steering)
    local daccel = math.abs(last_val.acceleration - next_position.acceleration)

    if (dsteer < DEADZONE and daccel < DEADZONE) then
        return
    end

    driver.move_car(next_position.acceleration, next_position.steering)
    last_val = next_position
end


local srv = http.create_server(PORT)
srv:add_route('/move', 'POST', move_car_controller)
srv:add_route('/move', 'PUT', move_car_controller)
srv:start()

tmr.alarm(0, REFRESH_INTERVAL, tmr.ALARM_AUTO, apply_movement_timer_cb)

print('Server started on port', PORT)
print('http://' .. wifi.sta.getip() .. ':' .. tostring(PORT) .. '/')
print('Refresing position every ' .. tostring(REFRESH_INTERVAL) .. 'ms')

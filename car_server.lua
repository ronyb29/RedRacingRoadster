local driver = require 'car_driver'
local http = require 'http_server'

local PORT = 80
local srv = http.create_server(PORT)
srv:add_route('/move', 'POST', driver.move)
srv:add_route('/move', 'PUT', driver.move)
srv:add_route('/index.html', 'GET', http.serve_file('index.html'))

srv:start()

print('Server started on port', PORT)
print('http://' .. wifi.sta.getip() .. ':' .. tostring(PORT) .. '/') 

local driver = require 'car_driver'
local http = require 'http_server'


srv = http.create_server(80)
srv:add_route('/move','POST', driver['move'])
srv:add_route('/move','PUT', driver['move'])
srv:add_route('/index.html','GET', http:serve_file('index.html'))


print('Wifi station status:',wifi.sta.status())
print('wifi station ip: ',wifi.sta.getip())

srv:start()

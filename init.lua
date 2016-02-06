
secrets = require 'secrets'

if srv == nil then
    wifi.setphymode(wifi.PHYMODE_N)
    wifi.setmode(wifi.STATION)
    wifi.sta.config(secrets.wifi_ssid,secrets.wifi_pwd)
    wifi.sta.connect()

    wifi.ap.config({ssid='RedRacingRoadster',pwd='redracingroadster'})

    print('wifi AP IP', wifi.ap.getip())
    print('Wifi station status:',wifi.sta.status())
    print('wifi station ip: ',wifi.sta.getip())
else
    srv:close()
end

dofile('tests_http_server.lua')

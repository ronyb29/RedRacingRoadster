print('Initial heap', node.heap())
node.setcpufreq(node.CPU160MHZ)
local secrets = require 'secrets'

local WIFI_INDICATOR_PIN = 4
gpio.mode(WIFI_INDICATOR_PIN, gpio.OUTPUT, gpio.FLOAT)
pwm.setup(WIFI_INDICATOR_PIN, 3, 512)
pwm.start(WIFI_INDICATOR_PIN)

wifi.setphymode(wifi.PHYMODE_B)
wifi.setmode(wifi.STATION)

--wifi.ap.config({ssid='RedRacingRoadster',pwd='redracingroadster'})
--print('wifi AP IP', wifi.ap.getip())
--dofile('tests_http_server.lua')

local function successfull_connect_cb()
    print('connected to AP')
    print('HostName', 'IP', 'MASK', 'GW')
    print(wifi.sta.gethostname(), wifi.sta.getip())
    pwm.close(WIFI_INDICATOR_PIN)
    gpio.mode(WIFI_INDICATOR_PIN, gpio.OUTPUT, gpio.FLOAT)
    gpio.write(WIFI_INDICATOR_PIN, gpio.HIGH)
    wifi.sta.eventMonStop('unreg all')
    print('Heap after connecting', node.heap())
    dofile('car_server.lua')
end

local wifi_ap_idx = 1
local function unsuccedsfull_connect_cb()
    print('Connection failed... ')
    print('Connecting to AP ' .. secrets.wifi_aps[wifi_ap_idx].ssid)
    wifi.sta.config(secrets.wifi_aps[wifi_ap_idx].ssid, secrets.wifi_aps[wifi_ap_idx].pwd, 1)

    wifi_ap_idx = wifi_ap_idx + 1
    if wifi_ap_idx > #secrets.wifi_aps then
        wifi_ap_idx = 1;
    end
end

wifi.sta.eventMonReg(wifi.STA_GOTIP, successfull_connect_cb)
wifi.sta.eventMonReg(wifi.STA_WRONGPWD, unsuccedsfull_connect_cb)
wifi.sta.eventMonReg(wifi.STA_APNOTFOUND, unsuccedsfull_connect_cb)
wifi.sta.eventMonReg(wifi.STA_FAIL, unsuccedsfull_connect_cb)
wifi.sta.eventMonStart(100)
wifi.sta.connect()

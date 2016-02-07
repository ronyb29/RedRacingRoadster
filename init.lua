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

wifi.sta.eventMonReg(wifi.STA_GOTIP,
    function()
        print('connected to AP')
        print('HostName', 'IP', 'MASK', 'GW')
        print(wifi.sta.gethostname(), wifi.sta.getip())
        pwm.close(WIFI_INDICATOR_PIN)
        gpio.mode(WIFI_INDICATOR_PIN, gpio.OUTPUT, gpio.FLOAT)
        gpio.write(WIFI_INDICATOR_PIN, gpio.HIGH)
        wifi.sta.eventMonStop('unreg all')
        print('Heap after connecting', node.heap())
        dofile('car_server.lua')
    end)
wifi.sta.eventMonStart(100)
wifi.sta.config(secrets.wifi_ssid, secrets.wifi_pwd, 1)

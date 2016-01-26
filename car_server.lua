-- A simple http server

if srv == nil then
    --wifi.setphymode(wifi.PHYMODE_G)
    wifi.setmode(wifi.STATIONAP)
    wifi.sta.config('YOURSSID','YOuRPwDD')
    wifi.sta.connect()

    wifi.ap.config({ssid='RedRacingRoadster',pwd='redracingroadster'})

    print('wifi AP IP', wifi.ap.getip())
    print('Wifi station status:',wifi.sta.status())
    print('wifi station ip: ',wifi.sta.getip())
else
    srv:close()
end

x_forward_pin = 2
x_backward_pin = 3
gpio.mode(x_forward_pin, gpio.OUTPUT,gpio.FLOAT)
gpio.mode(x_backward_pin, gpio.OUTPUT,gpio.FLOAT)

z_forward_pin = 5
z_backward_pin = 6
gpio.mode(z_forward_pin, gpio.OUTPUT,gpio.FLOAT)
gpio.mode(z_backward_pin, gpio.OUTPUT,gpio.FLOAT)


function current_file_size()
    current = file.seek('cur',0)
    size = file.seek('end',0)
    file.seek('set',current)
    return size
end

function serve_file(filename, conn)
    print ('opening file', filename)
    rv = file.open(filename, 'r')
    if not rv then
        conn:send('HTTP/1.0 500 File Not Found\r\n\r\n')
        return
    end


    print('reading', filename)

    local function sent_cb(connection)
        content = file.read(1024)
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
                end)
        end
    end

    conn:send('HTTP/1.0 200 OK\r\nContent-Length: ' .. current_file_size() ..'\r\n\r\n',
               sent_cb)

    print ('file queued:' .. filename)

end

function process_params(x, z)
    if x==1 then
        gpio.write(x_backward_pin,gpio.HIGH)
        gpio.write(x_forward_pin,gpio.LOW)
    elseif x==-1 then
        gpio.write(x_forward_pin,gpio.HIGH)
        gpio.write(x_backward_pin,gpio.LOW)
    else
        gpio.write(x_forward_pin,gpio.HIGH)
        gpio.write(x_backward_pin,gpio.HIGH)
    end

    if z==1 then
        gpio.write(z_backward_pin,gpio.HIGH)
        gpio.write(z_forward_pin,gpio.LOW)
    elseif z==-1 then
        gpio.write(z_forward_pin,gpio.HIGH)
        gpio.write(z_backward_pin,gpio.LOW)
    else
        gpio.write(z_forward_pin,gpio.HIGH)
        gpio.write(z_backward_pin,gpio.HIGH)
    end
end
process_params(0,0)

srv=net.createServer(net.TCP)

srv:listen(80, function(conn)
  conn:on('receive', function(conn,payload)
    print('Payload:', #payload, 'mem', node.heap())
    if node.heap() < 10000 then
        conn:close()
        return
    end

    url, raw_params = string.match(payload,'GET (/[%l%u]*)%??(%S*)')
    print ('URL:', url, 'PARAMS',raw_params)

    params={}
    for kvp in string.gmatch(raw_params, "[^&]+") do
        for k,v in string.gmatch(kvp, '(%S+)=(%S+)') do
            params[k] = v
        end
    end

    if url == '/' then
        serve_file('index.html', conn)
    elseif url == '/move' then
        process_params(tonumber(params['x']),tonumber(params['z']))
        conn:send('HTTP/1.0 200 OK\r\n\r\nFreeMem:'..node.heap(),
            function (conn, sent)
                conn:close()
            end)
    else
        conn:send('HTTP/1.0 404 Not Found\r\n\r\n',
            function (conn)
                conn:close()
            end)
    end
  end)
end)

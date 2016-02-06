
local http  = require 'http_server'
local utils = require 'utils'
local driver = require 'car_driver'

local function request_parser_tests()
    local example_payload = [[GET /?e=3&p=5 HTTP/1.1
    Host: 10.0.0.7
    Connection: keep-alive
    Cache-Control: max-age=0
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
    Upgrade-Insecure-Requests: 1
    User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.103 Safari/537.36
    Accept-Encoding: gzip, deflate, sdch
    Accept-Language: en-US,en;q=0.8,es;q=0.6]]
    
    local request = http.testctx.parse_request(example_payload)
    --print(cjson.encode(request))
    assert(request.method == 'GET')
    assert(request.url == '/')
    assert(utils.deep_compare(request.params, {e="3",p="5"}))
    
    headers = {}
    headers['Host']='10.0.0.7'
    headers['Connection']='keep-alive'
    headers['Accept']='text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
    headers["Cache-Control"]='max-age=0'
    headers["Upgrade-Insecure-Requests"]='1'
    headers["User-Agent"]='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.103 Safari/537.36'
    headers["Accept-Encoding"]='gzip, deflate, sdch'
    headers["Accept-Language"]='en-US,en;q=0.8,es;q=0.6'
    
    assert(utils.deep_compare(request.headers, headers))
end
request_parser_tests()

local function fff()
    local srv = http.create_server(80)
    srv.add_route('/move','POST', driver.move)
    srv.add_route('/move','PUT', driver.move)
    srv.add_route('/index.html','GET', http:serve_file('index.html'))

    utils.print_table(srv)
end
fff()



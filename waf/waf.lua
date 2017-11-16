
--[[

local libinject = require "resty.libinjection"
input = '-1\'union select 1,2,3,4,5,6--'
xss = '1<script>alert(0)</script>'
output = libinject.xss(input)
ngx.log(ngx.ERR,output)

--]]



function test()
    for k,v in pairs(args) do
        ngx.log(ngx.ERR,k..'---'..v)
    end
    if request_method == 'POST' then
    
    --body的长度为0
    if post_data == nil  then
        ngx.log(ngx.ERR,'body length is 0')
    end
    --匹配a=b或者a=b&c=d
    local regex = [[^!{\S+=\S+|\S+=\S+&$!}]] 
    local m = ngx.re.match(post_data, regex, "jo")
    local regex1 = [[{.*?}]] 
    local m1 = ngx.re.match(post_data, regex1, "jo")
    if m then
        data = m[0]
        data = Split(data,'&')
        for k,v in pairs(data) do
            ngx.log(ngx.ERR,k..'---'..v)
        end
    elseif m1 then
            data = cjson.decode(post_data)
            for k,v in pairs(data) do
                if type(v) == 'table' then
                    for key,value in pairs(v)do 
                        ngx.log(ngx.ERR,key..'--'..value)
                    end
                end
            --ngx.log(ngx.ERR,k..'---'..v)
            end
            
    else
        ngx.log(ngx.ERR,'not match')
        end
    
    end
    end




local cjson = require("cjson")
local request_headers     = ngx.req.get_headers()
local request_method      = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local User_Agent = request_headers['User-Agent'] or nil
local Cookie = request_headers['Cookie'] or nil
local Referer  = request_headers['Referer'] or nil
local request_host = request_headers['Host'] or nil
local request_uri = ngx.var.request_uri      --网站url
local remote_ip = ngx.var.remote_addr --客户端IP
ngx.req.read_body()
local post_data =  ngx.req.get_body_data() or ""
local time = ngx.time()
------------------------------------
local info = debug.getinfo(1, "S")
local path = info.source
path = string.sub(path, 2, -1)
path = string.match(path, "^.*/")  
------------------------------------


--检测table
function check_table(t)
    if next(t) == nil then
        ngx.log(ngx.ERR,"table is nil")
    else
        for k,v in pairs(t)do
            ngx.log(ngx.ERR,k.."----"..v)
        end
    end
end

--日志记录
function logging(time,ip,rule_id,msg)
    _t = "'packet':'"..request_method.." "..request_uri.." HTTP/1.1" 
    _t1 = ""
    for k,v in pairs(request_headers)do
        _t1 = _t1..k..":"..v
    end
    packet = _t.._t1..post_data.."'"
    file = io.open("/data/waf/waf.log","a+")
    text = "{'timestamp':"..time..",'ip':'"..ip.."','rule_id':"..rule_id..",'msg':'"..msg.."',"..packet.."}\n"
    file:write(text)
    file:close()
end



--分割字符串函数
function Split(szFullString, szSeparator)  
    local nFindStartIndex = 1  
    local nSplitIndex = 1  
    local nSplitArray = {}  
    while true do  
       local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)  
       if not nFindLastIndex then  
        nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))  
        break  
       end  
       nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)  
       nFindStartIndex = nFindLastIndex + string.len(szSeparator)  
       nSplitIndex = nSplitIndex + 1  
    end  
    return nSplitArray  
    end  



--遍历规则集
require"lfs"    
function findindir()
    local rule_set = {}
    
    path = path.."ruleset/"
    for file in lfs.dir(path) do    
        if file ~= "." and file ~= ".." then    
            local f = path..file      
            table.insert( rule_set,f ) 
             
        end    
    end
    return rule_set    
end    
--变量类型
function var_type( vars )
    if vars == 'request_uri'then
        t = {request_uri=request_uri}
    elseif vars == 'request_cookies' then
        t = {request_cookies=Cookie}
    elseif vars == 'request_referer' then
        t = {request_referer=Referer}
    elseif vars == 'request_post' then
        t = {request_post=post_data}
    elseif vars == 'request_host' then
        t = {request_host=request_host}
    elseif vars == 'User_Agent'then
        t = {User_Agent=User_Agent}
    elseif vars == 'remote_ip' then
        t = {remote_ip=remote_ip}
    elseif vars == 'args' then
        t = {
            request_uri=request_uri,
            request_cookies=Cookie,
            request_referer=Referer,
            request_post=post_data,
            request_host=request_host,
            User_Agent = User_Agent
        }
    else
        t = {}
    end
    --check_table(t)
    return t
end
--解码
function decode(translate,vars)
    _tmp = {}
    if translate == 'url_decode' then
        _t = var_type(vars)
        for k,v in pairs(_t)do
        translate_var = ngx.unescape_uri(v)
        _tmp[k]=string.lower( translate_var )
        
        end
        return _tmp
    else
        _t = var_type(vars)
        return _t
    end

    
end
--检测
function detect(table,var)
    for k,v in pairs(var)do
        m = ngx.re.match(v,table.pattern,'joi')
        if m then
            ngx.log(ngx.ERR,"tttttttttttttttttt")
            if table.log == 'yes' then
            logging(time,remote_ip,table.id,table.msg)
            end
            if table.status == 'deny' then
            ngx.exit(403)
            end
        end
    end
end

function whilepass()
    local path1 = path..'whitelist.json'
    local file = io.open(path1, "r")  
    local json = file:read("*a")  
    file:close()  
    local r = cjson.decode(json)
    for _, w in ipairs(r.rulerset) do
        var = decode(w.translate,w.vars.type)
        for k,v in pairs(var)do
            m = ngx.re.match(v,w.pattern,'joi')
            if m then
                return "true"
            else
                return "false"
            end
        end
    end

end



--读取规则集
function FileRead(rule_path)
    if whilepass() == "false" then
    for _,name in pairs(rule_path)do 
    m = ngx.re.match(name,'whitelist.json','joi') 
    if m == nil then
    local file = io.open(name, "r")  
    local json = file:read("*a")  
    file:close()  
    local r = cjson.decode(json)

    for _, w in ipairs(r.rulerset) do

        var = decode(w.translate,w.vars.type)
        detect(w,var)
    end
    end
    end
    end
end  
rule_set = findindir()
FileRead(rule_set)




    





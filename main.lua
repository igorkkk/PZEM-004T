do
answer = {
    voltage = "0",
    current = "0",
    activeP = "0",
    energy  = "0",
    adc = "0",
    heap = "0"
}
Broker = "iot.eclipse.org"
port = 1883
myClient = "PZEM004_01"
pass = "superpass"

mod = {} 
mod.publish = false

m = mqtt.Client(myClient, 30, myClient, pass)
m:lwt(myClient, 0, 0, 0)

function connecting()
    connect = require('mqttm')
    connect.connecting(m, Broker, port, mod, function ()connect = nil end)
end

m:on("offline", function(con)
      mod.publish = false
      m:close()
      connecting()
end)

publ = function()
    answer.adc = ""..adc.read(0)
    answer.heap = ""..node.heap()
    local sendMQ
    local getd = coroutine.create(function()
        for k, v in pairs(answer) do
            sendMQ(k, v)
            coroutine.yield()
        end
            collectgarbage()
    end)

    sendMQ = function(k, v)
        m:publish(myClient.."/"..k,v,0,0, 
            function(con) 
                coroutine.resume(getd)
        end)
    end
    coroutine.resume(getd)
end

connecting()

local next = tmr.create()
next:alarm(20000, 1, function()
    dofile("pzem.lua")  
    tmr.create():alarm(10000, 0, function()
        if mod.publish == true then
            publ()
        end
    end)
    
end)
end

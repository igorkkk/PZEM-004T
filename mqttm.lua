M={}
function M.connecting(m, Broker, port, mod, unload)
    local getConnect
    getConnect = function()    
       if wifi.sta.status() == 5 then 
            m:connect(Broker, port, 0, 0,
                function(con)
                    tmr.stop(1)
                    if mod then mod.publish = true end
                    if unload then
                        getConnect = nil
                        package.loaded["mqttm"]=nil
                        unload()
                    end
            end)
        end
    end
    tmr.alarm(1, 5000, 1, function()
        getConnect()
    end)
    getConnect()
end
return M

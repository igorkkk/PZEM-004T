-- works stable now
if not answer then answer = {} end

do
    local asknow = {
        voltage = "\176\192\168\001\001\000\026",
        current = "\177\192\168\001\001\000\027",
        activeP = "\178\192\168\001\001\000\028",
        energy  = "\179\192\168\001\001\000\029"
    }

    local now = function()
        local ask, getansw, check
        local dig = {}
        ask = coroutine.create(function()
            -- uart.alt(1)
            uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
            for k, v in pairs(asknow) do
                getansw(k)
                uart.write(0, v)
                coroutine.yield()
            end
            -- uart.alt(0)
            uart.setup(0, 115200, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)
            return
        end)

        getansw = function(k)
            local start = false
            local breaker = tmr.create()
            breaker:alarm(2000, 0, function()
                uart.on("data")
                answer[k] = "err"
                -- answer[k] = ""..math.random(1,100)
                coroutine.resume(ask)
            end)
            local i = 1
            uart.on("data", 1,
                function(data)
                    local s = string.byte(data)
                    if start == true or (s >= 0xA0 and s < 0xA4) then
                        start = true
                        dig[i] = s
                        i = i + 1
                        if i == 8 then
                            breaker:stop()
                            uart.on("data")
                            check(k)
                        end
                    end
                end, 0)
        end

        check = function(k)
            local sum = 0
            for i = 1, 6 do
                sum = sum + dig[i]
                i = i + 1
            end
            sum = bit.band(sum, 0xFF)
            --if sum ~= dig[7] then answer[k] = "err"
            if sum ~= dig[7] then answer[k] = "-1"
            elseif dig[1] == 0xA0 or dig[1] == 0xA1 then
                answer[k] = "" .. dig[3] .. "." .. dig[4]
            elseif dig[1] == 0xA2 then
                local s = dig[2] * 256 + dig[3]
                answer[k] = "" .. s
            elseif dig[1] == 0xA3 then
                local s = dig[2] * 65536 + dig[3] * 256 + dig[4]
                answer[k] = "" .. s
            end
            coroutine.resume(ask)
        end
        coroutine.resume(ask)
    end
    now()
end


local socket = require "socket"
local udp = socket.udp()

udp:settimeout(0)
udp:setsockname('*', 45167)

local world = {} -- the empty world-state
local data, msg_or_ip, port_or_nil
local entity, cmd, parms

local running = true

print "Beggining server loop."
while running do
        data, msg_or_ip, port_or_nil = udp:receivefrom()
        if data then
                -- more of these funky match paterns!
                entity, cmd, parms = data:match("^(%S*) (%S*) (.*)")

                if cmd == 'move' then
                        local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
                        assert(x and y) -- validation is better, but asserts will serve.
                        -- don't forget, even if you matched a "number", the result is still a string!
                        -- thankfully conversion is easy in lua.
                        x, y = tonumber(x), tonumber(y)
                        -- and finally we stash it away
                        local ent = world[entity] or {x=0, y=0}
                        world[entity] = {x=ent.x+x, y=ent.y+y}
                elseif cmd == 'at' then
                        local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
                        assert(x and y) -- validation is better, but asserts will serve.
                        x, y = tonumber(x), tonumber(y)
                        world[entity] = {x=x, y=y}
                elseif cmd == 'update' then
                        for k, v in pairs(world) do
                                udp:sendto(string.format("%s %s %f %f", k, 'at', v.x, v.y), msg_or_ip,  port_or_nil)
                        end
                elseif cmd == 'quit' then
                        running = false;
                elseif cmd == 'exit' then

                    
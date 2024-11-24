gameTest = {}

local socket = require "socket"

-- the address and port of the server
local address, port = "37.27.51.34", 45167

local entity -- entity is what we'll be controlling
local updaterate = 0.1 -- how long to wait, in seconds, before requesting an update
-- local x, y = 100, 100
local diffx, diffy = 0, 0

local world = {} -- the empty world-state
local t
_G.money = 10000

function gameTest.load()
    udp = socket.udp()
    udp:settimeout(0)
    udp:setpeername(address, port)

    math.randomseed(os.time())
    -- entity = tostring(math.random(99999))
    entity = nameInput.text
    world[entity] = {x = 320, y = 240, timestamp = os.time(), money = 10000} -- Initialize `world[entity]`
    local dg = string.format("%s %s %d %d %d", entity, 'at', 320, 240, 10000)
    udp:send(dg)

    t = 0
end

function gameTest.update(dt)
    t = t + dt -- increase t by the dt

    if love.keyboard.isDown('up') then diffy = diffy - (40 * dt) end
    if love.keyboard.isDown('down') then diffy = diffy + (40 * dt) end
    if love.keyboard.isDown('left') then diffx = diffx - (40 * dt) end
    if love.keyboard.isDown('right') then diffx = diffx + (40 * dt) end
    
    if t > updaterate then
        -- print(entity)
        -- print(diffx - world[entity].x .. "," .. diffy - world[entity].y)
        -- diffx, diffy = world[entity].x, world[entity].y
        local dg = string.format("%s %s %d %d", entity, 'move', diffx, diffy)
        udp:send(dg)
        diffx, diffy = 0, 0


        local dg = string.format("%s %s $", entity, 'update')
        udp:send(dg)


        t=t-updaterate -- set t for the next round
    end

    repeat
        data, msg = udp:receive()
        if msg and (msg ~= "timeout") then
            print("Received Data: " .. ", " .. msg)
        end

        if data then -- you remember, right? that all values in lua evaluate as true, save nil and false?
            ent, cmd, parms = data:match("^(%S*) (%S*) (.*)")
            
            -- print("Parsed data - Entity:", ent, "Command:", cmd, "Parameters:", parms)
            if cmd == 'at' then
                local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
                assert(x and y)
                x, y = tonumber(x), tonumber(y)
                world[ent] = {x=x, y=y, timestamp=os.time()}
            elseif cmd == 'exit' then
                print(ent .. " was just removed.")
                world[ent] = nil
            else
                print("unrecognised command:", cmd)
            end
        end
    until not data

    -- Check for entities that haven't been updated in the last second
    local currentTime = os.time()
    for k, v in pairs(world) do
        if currentTime - v.timestamp > 2 then
            print(k .. " was just removed due to inactivity.")
            world[k] = nil
        end
    end
end

function love.draw()
    -- pretty simple, we 
    for k, v in pairs(world) do
        love.graphics.print(k, v.x, v.y)
    end
end

function love.keypressed(key)
    if key == "[" then
        local dg = string.format("%s %s $", entity, 'quit')
        udp:send(dg)
    end
    if key == "]" or key == "escape" then -- Exit the game (Debug)
        love.event.quit()
    end
end

function love.quit()
    local rq = string.format("%s %s $", entity, 'exit')
    udp:send(rq)
    udp:close()
end


return gameTest

game = {}

local minigame = {}

local socket = require "socket"

-- the address and port of the server
local address, port = "37.27.51.34", 45167

local entity -- entity is what we'll be controlling
local updaterate = 0.1 -- how long to wait, in seconds, before requesting an update
-- local x, y = 100, 100
local diffx, diffy = 0, 0

world = {} -- the empty world-state
local t

function game.load()
    gamblingchildimage = love.graphics.newImage("Sprites/gamblingminor.png")
    childimageWidth = gamblingchildimage:getWidth()
    childimageHeight = gamblingchildimage:getHeight()

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

    minigame.current = require("Scenes/Minigames/roulette")
    minigame.current.load()
end

function game.update(dt)
    local nextminigame = minigame.current.update(dt)
    if nextminigame == "startSlots" then
        -- Switch to the game scene
        print("Switching to Slots!")
        minigame.current = require("Scenes/Minigames/slots")
        minigame.current.load()
    elseif nextminigame == "startRoulette" then
        -- Switch to the main menu scene
        print("Switching to Roulette!")
        minigame.current = require("Scenes/Minigames/roulette")
        minigame.current.load()
    end

    lobbyupdate(dt)
end

function lobbyupdate(dt)
    t = t + dt -- increase t by the dt

    if love.keyboard.isDown('up') then diffy = diffy - (100 * dt) end
    if love.keyboard.isDown('down') then diffy = diffy + (100 * dt) end
    if love.keyboard.isDown('left') then diffx = diffx - (100 * dt) end
    if love.keyboard.isDown('right') then diffx = diffx + (100 * dt) end
    
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
                print(entity .. " " .. world[entity].money)
                world[ent] = {x=x, y=y, timestamp=os.time(), money = world[entity].money}  -- Add default money
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
    love.graphics.setColor(1, 1, 1)
    minigame.current.draw()
    love.graphics.setColor(1, 1, 1)
    -- pretty simple, we 
    for k, v in pairs(world) do
        love.graphics.print(k, v.x, v.y-100)
        if v.x > screenWidthA/2 then
            love.graphics.draw(gamblingchildimage, v.x, v.y, rotation, -1, 1, childimageWidth / 2, childimageHeight / 2)
        else
            love.graphics.draw(gamblingchildimage, v.x, v.y, rotation, 1, 1, childimageWidth / 2, childimageHeight / 2)
        end
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

function game.setMoney(playerName, amount)
    if world[playerName] then
        world[playerName].money = amount
        -- Send update to server
        local dg = string.format("%s %s %d", playerName, 'money', amount)
        udp:send(dg)
        return true
    end
    return false
end

function game.addMoney(playerName, amount)
    if world[playerName] then
        world[playerName].money = world[playerName].money + amount
        -- Send update to server
        local dg = string.format("%s %s %d", playerName, 'money', world[playerName].money)
        udp:send(dg)
        return true
    end
    return false
end
return game

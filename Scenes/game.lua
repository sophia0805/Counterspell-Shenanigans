game = {}

local minigame = {}

local socket = require "socket"

-- the address and port of the server
local address, port = "37.27.51.34", 45169

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
    world[entity] = {params = {x = 320, y = 240, timestamp = os.time(), money = 10000}} -- Initialize `world[entity]`
    
    -- Send data in Lua table-like format
    local dg = string.format("%s %s {x=%d,y=%d,money=%d}", entity, 'at', 320, 240, 10000)
    udp:send(dg)

    t = 0

    minigame.current = require("Scenes/Minigames/slots")
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

local function parseData(data)
    -- Remove braces from the data string
    data = data:gsub("{", ""):gsub("}", "")
    local result = {}
    for k, v in string.gmatch(data, "([%w_]+)=([%w_.-]+)") do
        local number = tonumber(v)
        if number then
            result[k] = number
        else
            result[k] = v
        end
    end
    return result
end

function lobbyupdate(dt)
    t = t + dt
    local currentTime = os.time()

    -- Handle movement input
    if love.keyboard.isDown("up") then diffy = diffy - (100 * dt) end
    if love.keyboard.isDown("down") then diffy = diffy + (100 * dt) end
    if love.keyboard.isDown("left") then diffx = diffx - (100 * dt) end
    if love.keyboard.isDown("right") then diffx = diffx + (100 * dt) end

    if t > updaterate then
        -- Send movement update
        local moveParams = string.format("{x=%d,y=%d}", diffx, diffy)
        local dg = string.format("%s %s %s", entity, "move", moveParams)
        udp:send(dg)
        diffx, diffy = 0, 0

        -- Request updates from the server
        dg = string.format("%s %s {}", entity, "update")
        udp:send(dg)

        t = t - updaterate
    end

    repeat
        data, msg = udp:receive()
        if data then
            -- print("Received data:", data) -- Debug incoming data
            local ent, cmd, parms = data:match("^(%S*) (%S*) (.*)")
            if cmd == "update" then
                local params = parseData(parms)
                -- Debug print
                -- print("Decoded params for entity", ent)
                for k, v in pairs(params) do
                    -- print("Param:", k, v)
                end
                -- Initialize or update the entity in the world
                world[ent] = world[ent] or {x = 0, y = 0, params = {}}
                world[ent].x = params.x or world[ent].x
                world[ent].y = params.y or world[ent].y
                world[ent].params.money = params.money or world[ent].params.money
                -- Merge params
                for k, v in pairs(params) do
                    if k ~= "x" and k ~= "y" then
                        world[ent].params[k] = v
                    end
                end
                world[ent].timestamp = currentTime  -- Update timestamp
            elseif cmd == "exit" then
                world[ent] = nil
            else
                print("Unrecognized command:", cmd)
            end
        end
    until not data

    -- Cleanup inactive entities
    for k, v in pairs(world) do
        if currentTime - (v.timestamp or 0) > 2 then
            world[k] = nil
        end
    end
end

function game.setParameter(playerName, param, value)
    if world[playerName] then
        world[playerName].params = world[playerName].params or {} -- Ensure params table exists
        world[playerName].params[param] = value
        -- Send update to the server
        local params = string.format("{%s=%d}", param, value)
        local dg = string.format("%s %s %s", playerName, "at", params)
        udp:send(dg)
        
        return true
    end
    return false
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    minigame.current.draw()
    love.graphics.setColor(1, 1, 1)

    -- Debug entities in the world
    for k, v in pairs(world) do
        -- Verify coordinates
        if v.x and v.y then
            -- print(string.format("Drawing entity %s at (%d, %d)", k, v.x, v.y))
            love.graphics.print(k, v.x, v.y - 100) -- Display the entity name
            if gamblingchildimage then
                if v.x > (love.graphics.getWidth() / 2) then
                    love.graphics.draw(gamblingchildimage, v.x, v.y, 0, -1, 1, childimageWidth / 2, childimageHeight / 2)
                else
                    love.graphics.draw(gamblingchildimage, v.x, v.y, 0, 1, 1, childimageWidth / 2, childimageHeight / 2)
                end
            else
                -- Draw a rectangle if the image is missing
                love.graphics.setColor(1, 0, 0) -- Red for missing image
                love.graphics.rectangle("fill", v.x, v.y, 50, 50)
                love.graphics.setColor(1, 1, 1)
            end
        else
            print(string.format("Entity %s has invalid coordinates: (%s, %s)", k, tostring(v.x), tostring(v.y)))
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
        world[playerName].params.money = amount
        -- Send update to server
        local dg = string.format("%s %s %d", playerName, 'money', amount)
        udp:send(dg)
        return true
    end
    return false
end

function game.addMoney(playerName, amount)
    if world[playerName] then
        world[playerName].params.money = world[playerName].params.money + amount
        -- Send update to server
        local dg = string.format("%s %s %d", playerName, 'money', world[playerName].params.money)
        udp:send(dg)
        return true
    end
    return false
end
return game

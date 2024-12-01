local socket = require "socket"
local udp = socket.udp()

udp:settimeout(0)
udp:setsockname('*', 45169)

local world = {} -- The game world, with entity data
local running = true

-- Custom parser function
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

-- Helper function to serialize table to a Lua-like string
local function serializeTable(t)
    local result = {}
    for k, v in pairs(t) do
        if type(v) == "string" then
            v = '"' .. v .. '"'
        end
        table.insert(result, tostring(k) .. "=" .. tostring(v))
    end
    return "{" .. table.concat(result, ",") .. "}"
end

-- Define the cleanupEntity function
local function cleanupEntity(entity)
    world[entity] = nil
end

-- Server main loop
print("Starting server loop.")
while running do
    local data, msg_or_ip, port_or_nil = udp:receivefrom()
    if data then
        print("Received data:", data) -- Log incoming data for debugging
        local entity, cmd, parms = data:match("^(%S*) (%S*) (.*)")
        if cmd == "move" then
            local params = parseData(parms)
            local ent = world[entity] or {x = 0, y = 0, params = {}}
            ent.x = ent.x + (params.x or 0)
            ent.y = ent.y + (params.y or 0)
            ent.lastUpdate = os.time()  -- Update last active time
            world[entity] = ent
        elseif cmd == "at" then
            local params = parseData(parms)
            print("Server received 'at' command from", entity)
            print("Parameters:")
            for k, v in pairs(params) do
                print("  ", k, v)
            end
            local ent = world[entity] or {x = 0, y = 0, params = {}}
            ent.x = params.x or ent.x
            ent.y = params.y or ent.y
            -- Merge params
            for k, v in pairs(params) do
                if k ~= "x" and k ~= "y" then
                    ent.params[k] = v
                end
            end
            ent.lastUpdate = os.time()
            world[entity] = ent
        elseif cmd == "update" then
            if next(world) == nil then
                print("No entities to update.")
            else
                for k, v in pairs(world) do
                    local serialized = string.format(
                        "%s %s %s",
                        k,
                        "update",
                        serializeTable({x = v.x, y = v.y, money = (v.params.money or 0)})
                    )
                    print("Sending data:", serialized)  -- Added print statement
                    udp:sendto(serialized, msg_or_ip, port_or_nil)
                end
            end
        elseif cmd == "quit" then
            running = false
        elseif cmd == "exit" and world[entity] then
            cleanupEntity(entity)
            udp:sendto(string.format("%s %s", entity, "exit"), msg_or_ip, port_or_nil)
        else
            print("Unrecognized command:", cmd)
        end
    elseif msg_or_ip ~= "timeout" then
        print("Network error:", msg_or_ip)
    end

    -- Cleanup inactive entities
    for entity, entData in pairs(world) do
        if os.time() - (entData.lastUpdate or 0) > 10 then  -- 10 seconds timeout
            print("Removing inactive entity:", entity)
            world[entity] = nil
        end
    end

    socket.sleep(0.01)
end

print("Server shutting down.")

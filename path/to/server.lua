
local socket = require "socket"
local udp = socket.udp()

udp:settimeout(0)
udp:setsockname('*', 45167)

local world = {} -- the empty world-state
local data, msg_or_ip, port_or_nil
local entity, cmd, parms

local running = true

function cleanupLocalEntity(entity)
    -- Print debug info
    print("Cleaning up local reference to entity:", entity)

    -- Remove from world table
    world[entity] = nil

    -- Clear any local references to this entity
    if localEntityData then localEntityData[entity] = nil end
    if entitySprites then entitySprites[entity] = nil end
    if entitySounds then entitySounds[entity] = nil end

    -- Clear any targeting or interaction references
    if selectedEntity == entity then selectedEntity = nil end
    if targetEntity == entity then targetEntity = nil end

    -- Clear any queued actions involving this entity
    if actionQueue then
        for i = #actionQueue, 1, -1 do
            if actionQueue[i].target == entity then
                table.remove(actionQueue, i)
            end
        end
    end

 
   -- Force garbage collection (optional)
    collectgarbage("collect")

    -- Verify cleanup
    print("Local entity cleanup complete. Verifying removal:", entity)
    print("World entry exists:", world[entity] ~= nil)
end

-- In your receive/update loop:
if data then
    ent, cmd, parms = data:match("^(%S*) (%S*) (.*)")

    if cmd == 'exit' then
        print(ent .. " was just removed.")
        cleanupLocalEntity(ent)
        -- Verify cleanup was successful
        assert(world[ent] == nil, "Entity still exists locally after cleanup!")
    end
end


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
		elseif cmd == 'exit' and world[entity] then
			print(table.concat(world,", "))
			print("Someone left lol")
			cleanupLocalEntity(entity)
			--table.remove(world, entity)
			udp:sendto(string.format("%s %s", entity, 'exit'), msg_or_ip, port_or_nil)
		else
			print("unrecognised command:", cmd)
		end
	elseif msg_or_ip ~= 'timeout' then
		error("Unknown network error: "..tostring(msg))
	end
	
	socket.sleep(0.01)
end

print "Thank you."
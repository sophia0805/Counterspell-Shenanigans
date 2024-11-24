-- Just a connection test as I have never done multiplayer before.

gameTest = {}

local socket = require "socket"

-- the address and port of the server
local address, port = "37.27.51.34", 45167

local entity -- entity is what we'll be controlling
local updaterate = 0.1 -- how long to wait, in seconds, before requesting an update

local world = {} -- the empty world-state
local t

function gameTest.load()
	udp = socket.udp()
    udp:settimeout(0)
    udp:setpeername(address, port)

    math.randomseed(os.time()) 
	entity = tostring(math.random(99999))

    local dg = string.format("%s %s %d %d", entity, 'at', 320, 240)
	udp:send(dg) -- the magic line in question.
	
	-- t is just a variable we use to help us with the update rate in love.update.
	t = 0 -- (re)set t to 0
end

function gameTest.update(dt)
    t = t + dt -- increase t by the dt
	
	if t > updaterate then
		local x, y = 0, 0
		if love.keyboard.isDown('up') then 	y=y-(20*t) end
		if love.keyboard.isDown('down') then 	y=y+(20*t) end
		if love.keyboard.isDown('left') then 	x=x-(20*t) end
		if love.keyboard.isDown('right') then 	x=x+(20*t) end
        local dg = string.format("%s %s %f %f", entity, 'move', x, y)
        print("Moving: " .. x .. ", " .. y)
		udp:send(dg)

        local dg = string.format("%s %s $", entity, 'update')
		udp:send(dg)

		t=t-updaterate -- set t for the next round
	end

    repeat
		data, msg = udp:receive()
        if msg and data then
            print("Received Data: " .. data .. ", " .. msg)
        end

		if data then -- you remember, right? that all values in lua evaluate as true, save nil and false?
            ent, cmd, parms = data:match("^(%S*) (%S*) (.*)")
			if cmd == 'at' then
				local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
                assert(x and y)
				x, y = tonumber(x), tonumber(y)
				world[ent] = {x=x, y=y}
            else
				print("unrecognised command:", cmd)
			end
        elseif msg ~= 'timeout' then 
			error("Network error: "..tostring(msg))
		end
	until not data
end

function love.draw()
	-- pretty simple, we 
	for k, v in pairs(world) do
		love.graphics.print(k, v.x, v.y)
	end
end

return gameTest
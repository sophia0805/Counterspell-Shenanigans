game = {}

function game.load() -- Runs at the start.
    -- Create a websocket connection to server.
end

function game.update() -- Runs every frame
    -- Get data from the server and update other player positions. (If no data throughput)

end

function game.draw() -- Best practice to run draw calls here. Runs directly after game.update()

end

return game -- Returns the code back to the main.lua, so it can run it.

-- Drawing an image example
-- function love.load()
--  whale = love.graphics.newImage("whale.png")
-- end
-- function love.draw()
--  love.graphics.draw(whale, 300, 200)
-- end

-- function love.load()
--  sound = love.audio.newSource("music.ogg", "stream")
--  love.audio.play(sound)
-- end
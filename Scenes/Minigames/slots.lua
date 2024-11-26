-- Global money variable

local slots = {}

-- Game state
local game = {
    images = {},
    slots = {1, 1, 1},
    betAmount = 100,
    spinning = false,
    spinDuration = 0.5,
    result = "",
    resultTimer = 0
}

-- Constants
local SLOT_WIDTH = 100
local SLOT_HEIGHT = 120
local REEL_SPACING = 15
local SPIN_TIME = 0.5
function slots.load()
    -- Load images
    game.images = {
        love.graphics.newImage("Sprites/i1.jpg"),
        love.graphics.newImage("Sprites/i2.jpg"),
        love.graphics.newImage("Sprites/i3.jpg"),
        love.graphics.newImage("Sprites/i4.jpg"),
        love.graphics.newImage("Sprites/i5.jpg"),
    } 
    
    -- Set up fonts 
    font = love.graphics.newFont("/Fonts/VCR_OSD_MONO.ttf", 100 * math.min(scaleStuff("w"), scaleStuff("h"))) -- The font
    font1 = love.graphics.newFont("/Fonts/VCR_OSD_MONO.ttf", 75 * math.min(scaleStuff("w"), scaleStuff("h")))
    font2 = love.graphics.newFont("/Fonts/VCR_OSD_MONO.ttf", 50 * math.min(scaleStuff("w"), scaleStuff("h")))
    font3 = love.graphics.newFont("/Fonts/VCR_OSD_MONO.ttf", 25 * math.min(scaleStuff("w"), scaleStuff("h")))
    love.graphics.setFont(font)
    
    -- Set up sounds
    --game.sounds = {
    --    cheer = love.audio.newSource("cheer.mp3", "static"),
    --    unhappy = love.audio.newSource("unhappy.mp3", "static")
    --}
end

function slots.update(dt)
    if game.spinning then
        game.spinDuration = game.spinDuration + dt
        if game.spinDuration >= SPIN_TIME then
            game.spinning = false
            game.spinDuration = 0
            slots.checkWin()
        end
    end
    
    -- Update result message timer
    if game.resultTimer > 0 then
        game.resultTimer = game.resultTimer - dt
        if game.resultTimer <= 0 then
            game.result = ""
        end
    end
end

function slots.draw()

    
    -- Draw title with background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 195, 5, 250, 40, 20, 20)
    love.graphics.setColor(0, 1, 1)
    love.graphics.rectangle("line", 195, 5, 250, 40, 20, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Slot Machine", 200, 10)
    
    -- Draw slot machine reels
    local startX = (love.graphics.getWidth() - (3 * SLOT_WIDTH + 2 * REEL_SPACING)) / 2
    local startY = 150
    
    for i = 1, 3 do
        -- Draw reel background
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", 
            startX + (i-1) * (SLOT_WIDTH + REEL_SPACING), 
            startY, 
            SLOT_WIDTH, 
            SLOT_HEIGHT,
            10, 10
        )
        
        -- Draw symbol
        love.graphics.setColor(1, 1, 1)
        local img = game.images[game.slots[i]]
        if img then
            love.graphics.draw(img, 
                startX + (i-1) * (SLOT_WIDTH + REEL_SPACING), 
                startY, 
                0, 
                SLOT_WIDTH / img:getWidth(), 
                SLOT_HEIGHT / img:getHeight()
            )
        end
        
        -- Draw reel border
        love.graphics.setColor(1, 0.84, 0)
        love.graphics.rectangle("line", 
            startX + (i-1) * (SLOT_WIDTH + REEL_SPACING), 
            startY, 
            SLOT_WIDTH, 
            SLOT_HEIGHT,
            10, 10
        )
    end
    
    -- Draw spin button with styling
    local buttonX = love.graphics.getWidth() / 2 - 50
    local buttonY = 350
    love.graphics.setColor(0.3, 0.7, 0.3)
    love.graphics.rectangle("fill", buttonX, buttonY, 100, 40, 15, 15)
    love.graphics.setColor(0, 1, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", buttonX, buttonY, 100, 40, 15, 15)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SPIN", buttonX, buttonY + 10, 100, "center")
    
    -- Draw result message with background
    if game.result ~= "" then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", love.graphics.getWidth()/2 - 200, 395, 400, 50, 20, 20)
        love.graphics.setColor(1, 0.84, 0)
        love.graphics.rectangle("line", love.graphics.getWidth()/2 - 200, 395, 400, 50, 20, 20)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(game.result, 0, 400, love.graphics.getWidth(), "center")
    end

    local x = 0;
    for playerName, playerData in pairs(world) do
        -- Draw money display background and border
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", 5, 5+x, 175, 40, 20, 20)
        love.graphics.setColor(1, 0, 1)
        love.graphics.rectangle("line", 5, 5+x, 175, 40, 20, 20)
        -- Draw money display text
        love.graphics.setColor(1, 0.84, 0)
        love.graphics.print(playerName .. ": " .. tostring(playerData.money), 5, 8+x)
        x = x + 30

    end
    -- world[nameInput.text].money
end

function love.mousepressed(x, y, button)
    -- Check for spin button click
    love.graphics.print("H", love.graphics.getWidth() / 2 - 50, love.graphics.getHeight()/2 -100)
    local buttonX = love.graphics.getWidth() / 2 - 50
    local buttonY = love.graphics.getHeight()/2 -100
    slots.spin()
    
end

function slots.spin()
    for i = 1, 3 do
        game.slots[i] = love.math.random(1, #game.images)
    end

    if not world[nameInput.text] then
        world[nameInput.text] = {money = 1000}
    end
    
    if world[nameInput.text].money < game.betAmount then
        game.result = "You don't have enough money to play!"
        game.resultTimer = 2
        -- return
    end
    
    world[nameInput.text].money = world[nameInput.text].money - game.betAmount
    game.spinning = true
    
    -- Randomize slots

end

function slots.checkWin()
    local winAmount = 0
    
    -- Check for three of a kind
    if game.slots[1] == game.slots[2] and game.slots[2] == game.slots[3] then
        winAmount = game.betAmount * 5
        game.result = "Jackpot! You win $" .. winAmount .. "!"
        -- game.sounds.cheer:play()
    -- Check for two of a kind
    elseif game.slots[1] == game.slots[2] or game.slots[2] == game.slots[3] or game.slots[1] == game.slots[3] then
        winAmount = game.betAmount * 0.5
        game.result = "Matched two symbols! You win $" .. winAmount .. "!"
        -- game.sounds.cheer:play()
    else
        winAmount = game.betAmount * -1
        game.result = "You lost this round!"
        -- game.sounds.unhappy:play()
    end
    
    world[nameInput.text].money = world[nameInput.text].money + winAmount
    game.resultTimer = 2
end

return slots
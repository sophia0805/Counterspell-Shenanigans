local roulette = {}

-- Constants for table layout
local TABLE_WIDTH = 800
local TABLE_HEIGHT = 400
local WHEEL_RADIUS = 200
local BALL_RADIUS = 5

-- Roulette numbers in order (standard European roulette wheel)
local WHEEL_NUMBERS = {
    0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27,
    13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1,
    20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26
}

-- Colors for numbers
local NUMBER_COLORS = {
    [0] = {0, 0.5, 0}, -- Green for 0
}
-- Set red and black colors
for _, num in ipairs(WHEEL_NUMBERS) do
    if num > 0 then
        if num == 1 or num == 3 or num == 5 or num == 7 or num == 9 or
           num == 12 or num == 14 or num == 16 or num == 18 or num == 19 or
           num == 21 or num == 23 or num == 25 or num == 27 or num == 30 or
           num == 32 or num == 34 or num == 36 then
            NUMBER_COLORS[num] = {0.8, 0, 0} -- Red
        else
            NUMBER_COLORS[num] = {0, 0, 0} -- Black
        end
    end
end

-- Game state
local wheelAngle = 0
local ballAngle = 0
local ballSpeed = 0
local isSpinning = false
local currentBet = 0
local selectedNumber = nil
local gameResult = nil
local spinTime = 0
local spinDuration = 5

function roulette.load()
    font = love.graphics.newFont("/Fonts/VCR_OSD_MONO.ttf", 100 * math.min(scaleStuff("w"), scaleStuff("h"))) -- The font
    font1 = love.graphics.newFont("/Fonts/VCR_OSD_MONO.ttf", 70 * math.min(scaleStuff("w"), scaleStuff("h")))
    font2 = love.graphics.newFont("/Fonts/VCR_OSD_MONO.ttf", 50 * math.min(scaleStuff("w"), scaleStuff("h")))
    font3 = love.graphics.newFont("/Fonts/VCR_OSD_MONO.ttf", 28 * math.min(scaleStuff("w"), scaleStuff("h")))
    love.graphics.setFont(font3)
    love.graphics.setBackgroundColor(2, 51, 75, 1)
end

function roulette.update(dt)
    if isSpinning then
        spinTime = spinTime + dt
        
        -- Update wheel rotation
        wheelAngle = wheelAngle + dt * 2
        
        -- Update ball rotation and speed
        if spinTime < spinDuration then
            ballSpeed = math.max(10 * (1 - spinTime/spinDuration), 2)
            ballAngle = ballAngle + ballSpeed * dt
        else
            ballSpeed = 0
            isSpinning = false
            
            local finalAngle = ballAngle % (2 * math.pi)
            local segment = math.floor(finalAngle / (2 * math.pi) * 37) + 1
            gameResult = WHEEL_NUMBERS[segment]
            
            if selectedNumber == gameResult then
                game.addMoney(entity, currentBet * 35)
            end
        end
    end
    
    -- return nil
end

local function drawWheel()
    love.graphics.setFont(font3)
    love.graphics.push()
    love.graphics.translate(TABLE_WIDTH, TABLE_HEIGHT/1.5)
    
    -- Draw outer wheel
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.circle("fill", 0, 0, WHEEL_RADIUS)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.circle("line", 0, 0, WHEEL_RADIUS)
    
    -- Draw segments
    for i, number in ipairs(WHEEL_NUMBERS) do
        local angle = (i-1) * (2 * math.pi / 37) + wheelAngle
        local color = NUMBER_COLORS[number]
        love.graphics.setColor(color[1], color[2], color[3])
        
        -- Draw segment
        love.graphics.arc("fill", 0, 0, WHEEL_RADIUS-5, 
            angle, angle + (2 * math.pi / 37))
        
        -- Draw number
        love.graphics.setColor(1, 1, 1)
        local textX = (WHEEL_RADIUS-25) * math.cos(angle + math.pi/37)
        local textY = (WHEEL_RADIUS-25) * math.sin(angle + math.pi/37)
        love.graphics.print(tostring(number), textX-6, textY-6)
    end
    
    -- Draw ball
    if isSpinning or gameResult then
        love.graphics.setColor(0.9, 0.9, 0.9)
        local ballX = (WHEEL_RADIUS-20) * math.cos(ballAngle)
        local ballY = (WHEEL_RADIUS-20) * math.sin(ballAngle)
        love.graphics.circle("fill", ballX, ballY, BALL_RADIUS)
    end
    
    love.graphics.pop()
end

local function drawBettingTable()
    love.graphics.setFont(font2)
    -- Draw green background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 195, 5, 250, 40, 20, 20)
    love.graphics.setColor(0, 1, 1)
    love.graphics.rectangle("line", 195, 5, 250, 40, 20, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Roulette", 200, 10)
    
    love.graphics.setFont(font3)
    -- Draw number grid
    local gridX, gridY = 100, 100
    local cellWidth, cellHeight = 40, 40
    
    -- Numbers array matching the layout in your screenshot
    local numbers = {
        {3, 6, 9, 12, 15, 18, 21, 24, 27},
        {2, 5, 8, 11, 14, 17, 20, 23, 26},
        {1, 4, 7, 10, 13, 16, 19, 22, 25}
    }
    
    -- Draw 0 first
    love.graphics.setColor(0, 0.5, 0)
    love.graphics.rectangle("fill", gridX - cellWidth, gridY, cellWidth, cellHeight * 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("0", gridX - cellWidth + cellWidth/4, gridY + cellHeight)

    -- Draw main grid
    for row = 1, 3 do
        for col = 1, 9 do
            local number = numbers[row][col]
            local x = gridX + (col-1) * cellWidth
            local y = gridY + (row-1) * cellHeight
            
            -- Draw cell background
            love.graphics.setColor(NUMBER_COLORS[number][1], NUMBER_COLORS[number][2], NUMBER_COLORS[number][3])
            love.graphics.rectangle("fill", x, y, cellWidth, cellHeight)
            
            -- Draw borders
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", x, y, cellWidth, cellHeight)
            
            -- Draw number
            love.graphics.setColor(1, 1, 1)
            if number < 10 then
                love.graphics.print(tostring(number), x + cellWidth/3, y + cellHeight/4)
            else
                love.graphics.print(tostring(number), x + cellWidth/4, y + cellHeight/4)
            end
            
            -- Highlight selected number
            if selectedNumber == number then
                love.graphics.setColor(1, 1, 0, 0.3)
                love.graphics.rectangle("fill", x, y, cellWidth, cellHeight)
            end
        end
    end
end

function roulette.draw()
    -- Draw background
    
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    drawBettingTable()
    drawWheel()
    
    -- Draw UI text
    love.graphics.setFont(font2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Current Bet: $" .. currentBet, love.graphics.getWidth()-300, 5)

    
    -- Draw instructions
    love.graphics.print("Click numbers to select bet", 50, TABLE_HEIGHT-30)
    love.graphics.print("Use UP/DOWN to change bet", 50, TABLE_HEIGHT-15)
    love.graphics.print("Press SPACE to spin", 250, TABLE_HEIGHT-30)

    
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
end

function roulette.mousepressed(x, y, button)
    if not isSpinning then
        local gridX, gridY = 100, 100
        local cellWidth, cellHeight = 100, 100
        
        -- Check zero
        if x >= gridX - cellWidth and x <= gridX and
           y >= gridY and y <= gridY + cellHeight * 3 then
            selectedNumber = 0
            -- return
        end
        
        -- Check main grid
        local numbers = {
            {3, 6, 9, 12, 15, 18, 21, 24, 27},
            {2, 5, 8, 11, 14, 17, 20, 23, 26},
            {1, 4, 7, 10, 13, 16, 19, 22, 25}
        }
        
        for row = 1, 3 do
            for col = 1, 9 do
                local btnX = gridX + (col-1) * cellWidth
                local btnY = gridY + (row-1) * cellHeight
                
                if x >= btnX and x <= btnX + cellWidth and
                   y >= btnY and y <= btnY + cellHeight then
                    selectedNumber = numbers[row][col]
                    -- return
                end
            end
        end
    end
end

function roulette.keypressed(key)
    if key == "space" and not isSpinning and selectedNumber ~= nil and currentBet > 0 then
        if world[entity].money >= currentBet then
            isSpinning = true
            spinTime = 0
            ballSpeed = 10
            gameResult = nil
            game.addMoney(entity, -currentBet)
        end
    elseif key == "w" then
        currentBet = math.min(currentBet + 100, world[entity].money)
    elseif key == "s" then
        currentBet = math.max(currentBet - 100, 0)
    end
end
return roulette
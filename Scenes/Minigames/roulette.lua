-- The Roulette minigame
roulette = {}

-- Constants
local WINDOW_WIDTH = 800
local WINDOW_HEIGHT = 600
local BLOCK_WIDTH = 120
local BLOCK_HEIGHT = 40
local PLAYER_SIZE = 40
local BALL_RADIUS = 25
local GRAVITY = 400
local BOUNCE_DAMPING = 0.9
local BALL_SPEED = 300

function roulette.load()
    -- Load player image and give them a position.
    -- Load roulette game sprites. (Ball, red side / blue side, etc)
    state = {
        -- Player setup
        player = {
            x = 200,
            y = WINDOW_HEIGHT - BLOCK_HEIGHT - PLAYER_SIZE,
            isWhite = true,
            money = 100,
            colorTimer = 0
        },
        
        -- Ball setup
        ball = {
            x = WINDOW_WIDTH / 2,
            y = WINDOW_HEIGHT / 4,
            dx = BALL_SPEED,
            dy = 0
        },
        
        -- Initialize blocks array
        blocks = {},
        
        -- Game time
        time = 0
    }
    
    -- Create initial blocks
    for i = 0, math.floor(WINDOW_WIDTH / BLOCK_WIDTH) + 1 do
        table.insert(state.blocks, {
            x = i * BLOCK_WIDTH,
            y = WINDOW_HEIGHT - BLOCK_HEIGHT,
            isWhite = i % 2 == 0
        })
    end
end

function roulette.update(dt)
    -- Update game time
    state.time = state.time + dt
    
    -- Update ball physics
    state.ball.x = state.ball.x + state.ball.dx * dt
    state.ball.y = state.ball.y + state.ball.dy * dt
    state.ball.dy = state.ball.dy + GRAVITY * dt
    
    -- Ball bounce off bottom
    if state.ball.y > WINDOW_HEIGHT - BLOCK_HEIGHT - BALL_RADIUS then
        state.ball.y = WINDOW_HEIGHT - BLOCK_HEIGHT - BALL_RADIUS
        state.ball.dy = -math.abs(state.ball.dy) * BOUNCE_DAMPING
    end
    -- Ball bounce off walls
    if state.ball.x > WINDOW_WIDTH - BALL_RADIUS then
        state.ball.x = WINDOW_WIDTH - BALL_RADIUS
        state.ball.dx = -math.abs(state.ball.dx)
    elseif state.ball.x < BALL_RADIUS then
        state.ball.x = BALL_RADIUS
        state.ball.dx = math.abs(state.ball.dx)
    end
    
    -- Update blocks
    for _, block in ipairs(state.blocks) do
        block.x = block.x - 200 * dt
    end
    
    -- Remove off-screen blocks
    while #state.blocks > 0 and state.blocks[1].x + BLOCK_WIDTH < 0 do
        table.remove(state.blocks, 1)
    end
    
    -- Add new blocks
    local lastBlock = state.blocks[#state.blocks]
    if lastBlock.x + BLOCK_WIDTH < WINDOW_WIDTH then
        table.insert(state.blocks, {
            x = lastBlock.x + BLOCK_WIDTH,
            y = WINDOW_HEIGHT - BLOCK_HEIGHT,
            isWhite = not lastBlock.isWhite
        })
    end
    
    -- Update player color
    state.player.colorTimer = state.player.colorTimer + dt
    if state.player.colorTimer >= 2 then
        state.player.isWhite = not state.player.isWhite
        state.player.colorTimer = 0
    end
    
    -- Handle player movement
    if love.keyboard.isDown('left') then
        state.player.x = math.max(0, state.player.x - 300 * dt)
    end
    if love.keyboard.isDown('right') then
        state.player.x = math.min(WINDOW_WIDTH - PLAYER_SIZE, state.player.x + 300 * dt)
    end
    
    -- Check collisions and update money
    checkCollisions()
end

function roulette.draw()
    -- Draw background
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
    love.graphics.clear()
    
    -- Draw blocks
    for _, block in ipairs(state.blocks) do
        if block.isWhite then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.rectangle("fill", block.x, block.y, BLOCK_WIDTH, BLOCK_HEIGHT)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("line", block.x, block.y, BLOCK_WIDTH, BLOCK_HEIGHT)
    end
    
    -- Draw ball
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.circle("fill", state.ball.x, state.ball.y, BALL_RADIUS)
    love.graphics.setColor(0.9, 0.3, 0.3)
    love.graphics.circle("fill", state.ball.x, state.ball.y, BALL_RADIUS * 0.7)
    
    -- Draw player
    if state.player.isWhite then
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0, 0, 0)
    end
    love.graphics.rectangle("fill", state.player.x, state.player.y, PLAYER_SIZE, PLAYER_SIZE)
    
    -- Draw money counter
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 5, 5, 150, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Money: $" .. math.floor(state.player.money), 10, 10)
end

-- Helper function for collision detection
function checkCollisions()
    -- Ball collision with player
    local dx = state.player.x + PLAYER_SIZE/2 - state.ball.x
    local dy = state.player.y + PLAYER_SIZE/2 - state.ball.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance < BALL_RADIUS + PLAYER_SIZE/2 then
        state.player.money = state.player.money - 10
    end
    
    -- Check if player is on wrong color block
    local playerBlockIndex = math.floor(state.player.x / BLOCK_WIDTH) + 1
    if playerBlockIndex <= #state.blocks then
        local currentBlock = state.blocks[playerBlockIndex]
        if currentBlock and currentBlock.isWhite ~= state.player.isWhite then
            state.player.money = state.player.money - 0.5
        end
    end
end

return roulette
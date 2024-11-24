-- The main menu for the program
mainMenu = {}

local suit = require("Libraries/SUIT")

-- Load scaling libraries
local CScreen = require("Libraries/cscreen")

love.graphics.setDefaultFilter("nearest", "nearest")
-- local optionsIcon = love.graphics.newImage("Sprites/gearIcon.png")

nameInput = {text = ""}

function mainMenu.load()
    love.window.setTitle("Awesome Game - Main Menu")
    screenWidthA = love.graphics.getWidth()
    screenHeightA = love.graphics.getHeight()
    screenWidth = 1920
    screenHeight = 1080

    love.math.setRandomSeed(os.time())

    -- Load scaling
    CScreen.init(1920, 1080, true)

    -- Load sound(s)
    -- bgSong = love.audio.newSource("Sounds/bgmusic.mp3", "stream")
    -- bgSong:setLooping(true)
    -- bgSong:setVolume(0.2)

    -- selectSound = love.audio.newSource("Sounds/select.wav", "stream")

    -- Play bg song
    -- bgSong:play()

    -- Set SUIT colors
    suit.theme.color.normal.fg = {255,255,255}
    suit.theme.color.hovered = {bg = {200,230,255}, fg = {0,0,0}}
    suit.theme.color.active = {bg = {150,150,150}, fg = {0,0,0}}

    -- -- Load font
    font = love.graphics.newFont("/Fonts/VCR_OSD_MONO.ttf", 100 * math.min(scaleStuff("w"), scaleStuff("h"))) -- The font
    font1 = love.graphics.newFont("/Fonts/VCR_OSD_MONO.ttf", 75 * math.min(scaleStuff("w"), scaleStuff("h")))
    font2 = love.graphics.newFont("/Fonts/VCR_OSD_MONO.ttf", 50 * math.min(scaleStuff("w"), scaleStuff("h")))
    font3 = love.graphics.newFont("/Fonts/VCR_OSD_MONO.ttf", 25 * math.min(scaleStuff("w"), scaleStuff("h")))
    love.graphics.setFont(font)
    love.keyboard.setKeyRepeat(true)

    -- print(love.filesystem.read("saveFile.txt"))
end

function mainMenu.update(dt)
    -- Move GUI a bit
    -- menuGUIUpdate(dt)
    
    -- Create suit GUI elements
    suit.Input(nameInput, screenWidthA / 2 - 200, 75 + screenHeightA/2, 400, 75)

    if suit.Button("Start", ((screenWidth / 2) - 200) * scaleStuff("w"), (screenHeight - 275) * scaleStuff("h"),
            400 * scaleStuff("w"), 150 * scaleStuff("h")).hit then
                if nameInput.text ~= "" then
                    -- bgSong:stop()
                    -- selectSound:play()
                    return "startGame"
                end
    end
    -- print((((screenWidth / 2) - 200) * scaleStuff("w")) .. "," .. ((screenHeight - 275) * scaleStuff("h")))
end

function mainMenu.draw()
    -- Set the scaling
    CScreen.apply()

    -- Draw Background
    love.graphics.clear(2 / 255, 51 / 255, 79 / 255)

    CScreen.cease()

    mainMenu.drawSUIT()
end

function mainMenu.drawSUIT() -- Draws SUIT Elements
    suit.draw()
end

function menuGUIUpdate(dt)
    
end

function love.textinput(t)
    suit.textinput(t)
end

function love.keypressed(key)
    suit.keypressed(key)
    
    if key == "]" or key == "escape" then -- Exit the game (Debug)
    love.event.quit()
    end
end

function scaleStuff(widthorheight)
    local scale = 1
    if widthorheight == "w" then -- width calc
        scale = screenWidthA / screenWidth
    elseif widthorheight == "h" then -- height calc
        scale = screenHeightA / screenHeight
    else
        print("Function usage error: scaleStuff() w/h not specified.")
    end

    return scale
end

-- Scaling Function
function love.resize(width, height)
    CScreen.update(width, height)
end

return mainMenu
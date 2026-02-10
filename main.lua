--[[
    GD50 2018
    Pong Remake

    -- Main Program --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Originally programmed by Atari in 1972. Features two
    paddles, controlled by players, with the goal of getting
    the ball past your opponent's edge. First to 10 points wins.

    This version is built to more closely resemble the NES than
    the original Pong machines or the Atari 2600 in terms of
    resolution, though in widescreen (16:9) so it looks nicer on
    modern systems.
]]

-- push is a library that will allow us to draw our game at a virtual
-- resolution, instead of however large our window is; used to provide
-- a more retro aesthetic
--
-- https://github.com/Ulydev/push
push = require 'push'

-- the "Class" library we're using will allow us to represent anything in
-- our game as code, rather than keeping track of many disparate variables and
-- methods
--
-- https://github.com/vrld/hump/blob/master/class.lua
Class = require 'class'

-- our Paddle class, which stores position and dimensions for each Paddle
-- and the logic for rendering them
require 'Paddle'

require 'Goal'

-- our Ball class, which isn't much different than a Paddle structure-wise
-- but which will mechanically function very differently
require 'Ball'

-- size of our actual window
WINDOW_WIDTH = 540
WINDOW_HEIGHT = 960

-- size we're trying to emulate with push
VIRTUAL_WIDTH = 243
VIRTUAL_HEIGHT = 433

-- paddle movement speed
PADDLE_SPEED = 180

--[[
    Called just once at the beginning of the game; used to set up
    game objects, variables, etc. and prepare the game world.
]]
function love.load()
    -- set love's default filter to "nearest-neighbor", which essentially
    -- means there will be no filtering of pixels (blurriness), which is
    -- important for a nice crisp, 2D look
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- set the title of our application window
    love.window.setTitle('Pong')

    -- seed the RNG so that calls to random are always random
    math.randomseed(os.time())

    -- initialize our nice-looking retro text fonts
    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    love.graphics.setFont(smallFont)

    -- set up our sound effects; later, we can just index this table and
    -- call each entry's `play` method
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    -- initialize our virtual resolution, which will be rendered within our
    -- actual window no matter its dimensions
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true,
        canvas = false
    })

    -- initialize our player paddles; make them global so that they can be
    -- detected by other functions and modules
    player1 = Paddle(VIRTUAL_WIDTH / 2 - 10, 45.2 + 5, 20, 5)
    player2 = Paddle(VIRTUAL_WIDTH / 2 - 10, VIRTUAL_HEIGHT - 45.2 - 5, 20, 5)

    -- place a ball in the middle of the screen
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    goal1 = Goal(1)
    goal2 = Goal(2)
    -- initialize score variables
    player1Score = 0
    player2Score = 0

    -- either going to be 1 or 2; whomever is scored on gets to serve the
    -- following turn
    servingPlayer = 1

    -- player who won the game; not set to a proper value until we reach
    -- that state in the game
    winningPlayer = 0

    -- the state of our game; can be any of the following:
    -- 1. 'start' (the beginning of the game, before first serve)
    -- 2. 'serve' (waiting on a key press to serve the ball)
    -- 3. 'play' (the ball is in play, bouncing between paddles)
    -- 4. 'done' (the game is over, with a victor, ready for restart)
    gameState = 'start'
end

--[[
    Called whenever we change the dimensions of our window, as by dragging
    out its bottom corner, for example. In this case, we only need to worry
    about calling out to `push` to handle the resizing. Takes in a `w` and
    `h` variable representing width and height, respectively.
]]
function love.resize(w, h)
    push:resize(w, h)
end

--[[
    Called every frame, passing in `dt` since the last frame. `dt`
    is short for `deltaTime` and is measured in seconds. Multiplying
    this by any changes we wish to make in our game will allow our
    game to perform consistently across all hardware; otherwise, any
    changes we make will be applied as fast as possible and will vary
    across system hardware.
]]
function love.update(dt)
    if gameState == 'serve' then
        -- before switching to play, initialize ball's velocity based
        -- on player who last scored
        ball.dx = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dy = math.random(140, 200)
        else
            ball.dy = -math.random(140, 200)
        end
    elseif gameState == 'play' then
        -- detect ball collision with paddles, reversing dy if true and
        -- slightly increasing it, then altering the dy based on the position
        -- at which it collided, then playing a sound effect
        if ball:collides(player1) then
            -- Find the new velocities
            local vxTotal = ball.dx - player1.dx
            local vyTotal = ball.dy - player1.dy
            local newVelX1 = (ball.dx * (ball.mass - player1.mass) + (2 * player1.mass * player1.dx)) /
                (ball.mass + player1.mass)
            local newVelY1 = (ball.dy * (ball.mass - player1.mass) + (2 * player1.mass * player1.dy)) /
                (ball.mass + player1.mass)
            local newVelX2 = vxTotal + newVelX1
            local newVelY2 = vyTotal + newVelY1

            -- Move the circles so that they don't overlap
            local midpointX = (ball.x + player1.x) / 2
            local midpointY = (ball.y + ball.y) / 2
            local dist = math.sqrt((ball.x - player1.x) ^ 2 + (ball.y - player1.y) ^ 2)
            ball.x = midpointX + ball.width * (ball.x - player1.x) / dist
            ball.y = midpointY + ball.width * (ball.y - player1.y) / dist
            -- player1.x = midpointX + player1.width * (player1.x - ball.x) / dist
            -- player1.y = midpointY + player1.width * (player1.y - ball.y) / dist

            -- Update the velocities
            ball.dx = newVelX1
            ball.dy = newVelY1
            -- player1.dx = newVelX2
            -- player1.dy = newVelY2

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            -- Find the new velocities
            local vxTotal = ball.dx - player2.dx
            local vyTotal = ball.dy - player2.dy
            local newVelX1 = (ball.dx * (ball.mass - player2.mass) + (2 * player2.mass * player2.dx)) /
                (ball.mass + player2.mass)
            local newVelY1 = (ball.dy * (ball.mass - player2.mass) + (2 * player2.mass * player2.dy)) /
                (ball.mass + player2.mass)
            local newVelX2 = vxTotal + newVelX1
            local newVelY2 = vyTotal + newVelY1

            -- Move the circles so that they don't overlap
            local midpointX = (ball.x + player2.x) / 2
            local midpointY = (ball.y + ball.y) / 2
            local dist = math.sqrt((ball.x - player2.x) ^ 2 + (ball.y - player2.y) ^ 2)
            ball.x = midpointX + ball.width * (ball.x - player2.x) / dist
            ball.y = midpointY + ball.width * (ball.y - player2.y) / dist
            -- player2.x = midpointX + player2.width * (player2.x - ball.x) / dist
            -- player2.y = midpointY + player2.width * (player2.y - ball.y) / dist

            -- Update the velocities
            ball.dx = newVelX1
            ball.dy = newVelY1
            -- player2.dx = newVelX2
            -- player2.dy = newVelY2

            sounds['paddle_hit']:play()
        end

        if goal1:collides(ball) or goal2:collides(ball) then
            ball.dx = 0.9 * ball.dx
            ball.dy = -0.9 * ball.dy

            sounds['wall_hit']:play()
        end

        if goal1:collides(player1) then
            -- collision on the left side of goal1
            if (player1.x - player1.width) <= (goal1.x + goal1.width) then
                -- Update X position with boundary checking
                if player1.dx < 0 then
                    player1.x = math.max(goal1.x + goal1.width + player1.width, player1.x + player1.dx * dt)
                else
                    player1.x = math.min(VIRTUAL_WIDTH - player1.width, player1.x + player1.dx * dt)
                end

                -- Update Y position with boundary checking (using provided bounds)
                if player1.dy < 0 then
                    player1.y = math.max(goal1.y + goal1.height + player1.width + 1, player1.y + player1.dy * dt)
                elseif player1.dy > 0 then
                    player1.y = math.min(goal1.y + goal1.height - player1.width, player1.y + player1.dy * dt)
                end
            end
        end
        -- detect upper and lower screen boundary collision, playing a sound
        -- effect and reversing dy if true
        if ball.x <= 0 then
            ball.x = 0
            ball.dx = -ball.dx
            sounds['wall_hit']:play()
        end

        -- -4 to account for the ball's size
        if ball.x >= VIRTUAL_WIDTH - ball.width then
            ball.x = VIRTUAL_WIDTH - ball.width
            ball.dx = -ball.dx
            sounds['wall_hit']:play()
        end

        -- if we reach the left or right edge of the screen, go back to serve
        -- and update the score and serving player
        if ball.y < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            -- if we've reached a score of 10, the game is over; set the
            -- state to done so we can show the victory message
            if player2Score == 10 then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                -- places the ball in the middle of the screen, no velocity
                ball:reset()
            end
        end

        if ball.y > VIRTUAL_HEIGHT then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()

            if player1Score == 10 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end
    end

    --
    -- paddles can move no matter what state we're in
    --
    -- player 1 movement (WASD: A/D for X-axis, W/S for Y-axis)
    if love.keyboard.isDown('a') then
        player1.dx = -PADDLE_SPEED
    elseif love.keyboard.isDown('d') then
        player1.dx = PADDLE_SPEED
    else
        player1.dx = 0
    end

    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    -- player 2 movement (Arrow keys: left/right for X-axis, up/down for Y-axis)
    if love.keyboard.isDown('left') then
        player2.dx = -PADDLE_SPEED
    elseif love.keyboard.isDown('right') then
        player2.dx = PADDLE_SPEED
    else
        player2.dx = 0
    end

    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    -- update our ball based on its DX and DY only if we're in play state;
    -- scale the velocity by dt so movement is framerate-independent
    if gameState == 'play' then
        ball:update(dt)
    end

    -- Player 1 (top half): can only move between y=0 and the middle line
    player1:update(dt, 0, VIRTUAL_HEIGHT / 2)
    -- Player 2 (bottom half): can only move between the middle line and the bottom
    player2:update(dt, VIRTUAL_HEIGHT / 2, VIRTUAL_HEIGHT)
end

--[[
    A callback that processes key strokes as they happen, just the once.
    Does not account for keys that are held down, which is handled by a
    separate function (`love.keyboard.isDown`). Useful for when we want
    things to happen right away, just once, like when we want to quit.
]]
function love.keypressed(key)
    -- `key` will be whatever key this callback detected as pressed
    if key == 'escape' then
        -- the function LÖVE2D uses to quit the application
        love.event.quit()
        -- if we press enter during either the start or serve phase, it should
        -- transition to the next appropriate state
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            -- game is simply in a restart phase here, but will set the serving
            -- player to the opponent of whomever won for fairness!
            gameState = 'serve'

            ball:reset()

            -- reset scores to 0
            player1Score = 0
            player2Score = 0

            -- decide serving player as the opposite of who won
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end

--[[
    Called each frame after update; is responsible simply for
    drawing all of our game objects and more to the screen.
]]
function love.draw()
    -- begin drawing with push, in our virtual resolution
    push:start()

    love.graphics.clear(255 / 255, 226 / 255, 172 / 255, 255 / 255)

    -- render different things depending on which part of the game we're in
    if gameState == 'start' then
        -- UI messages
        love.graphics.setFont(largeFont)
        love.graphics.printf('Welcome to Air Hockey!', 0, VIRTUAL_HEIGHT / 2 - 20, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to begin!', 0, VIRTUAL_HEIGHT / 2 + 10, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        -- UI messages
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!",
            0, VIRTUAL_HEIGHT / 2 - 20, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to serve!', 0, VIRTUAL_HEIGHT / 2 + 10, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        -- no UI messages to display in play
    elseif gameState == 'done' then
        -- UI messages
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!',
            0, VIRTUAL_HEIGHT / 2 - 20, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, VIRTUAL_HEIGHT / 2 + 10, VIRTUAL_WIDTH, 'center')
    end

    -- show the score before ball is rendered so it can move over the text
    displayScore()


    love.graphics.setColor(255 / 255, 28 / 255, 11 / 255, 255 / 255)
    love.graphics.line(0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, VIRTUAL_HEIGHT / 2)
    love.graphics.circle("line", VIRTUAL_WIDTH / 2, 0, 3 * VIRTUAL_WIDTH / 8)
    love.graphics.circle("line", VIRTUAL_WIDTH / 2, VIRTUAL_HEIGHT, 3 * VIRTUAL_WIDTH / 8)


    love.graphics.setColor(255 / 255, 28 / 255, 11 / 255, 128 / 255)
    love.graphics.line(0, VIRTUAL_HEIGHT / 4 + 20, VIRTUAL_WIDTH, VIRTUAL_HEIGHT / 4 + 20)
    love.graphics.line(0, 3 * VIRTUAL_HEIGHT / 4 - 20, VIRTUAL_WIDTH, 3 * VIRTUAL_HEIGHT / 4 - 20)

    love.graphics.setColor(12 / 255, 12 / 255, 12 / 255, 255 / 255)
    ball:render()
    love.graphics.setColor(26 / 255, 118 / 255, 255 / 255, 255 / 255)
    player1:render()
    love.graphics.setColor(255 / 255, 26 / 255, 67 / 255, 255 / 255)
    player2:render()

    love.graphics.setColor(0, 0, 0, 1)
    goal1:render()
    goal2:render()
    love.graphics.setColor(12 / 255, 12 / 255, 12 / 255, 255 / 255)



    -- display FPS for debugging; simply comment out to remove
    displayFPS()

    -- end our drawing to push
    push:finish()
end

--[[
    Simple function for rendering the scores.
]]
function displayScore()
    -- score display
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50,
        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
        VIRTUAL_HEIGHT / 3)
end

--[[
    Renders the current FPS.
]]
function displayFPS()
    -- simple FPS display across all states
    -- love.graphics.setFont(smallFont)
    -- love.graphics.setColor(0, 255 / 255, 0, 255 / 255)
    -- love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
    -- love.graphics.setColor(255, 255, 255, 255)
end

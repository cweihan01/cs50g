--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level
    self.levelChanged = params.levelChanged
    self.recoverPoints = params.recoverPoints
    self.powerups = params.powerups
    self.powerupEffects = params.powerupEffects

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)

    self.spawnTimer = math.random(3, 10)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    self.ball:update(dt)
    for k, altBall in pairs(self.powerupEffects['altBalls']) do
        altBall:update(dt)
    end

    for k, powerup in pairs(self.powerups) do
        powerup:update(dt)
    end

    -- handle collision of main ball with paddle and bricks
    self:ballPaddleHandler(self.ball, self.paddle)
    self:ballBricksHandler(self.ball, self.bricks)

    -- handle collision of extra balls (if any) with paddle and bricks
    for k, altBall in pairs(self.powerupEffects['altBalls']) do
        self:ballPaddleHandler(altBall, self.paddle)
        self:ballBricksHandler(altBall, self.bricks)
    end

    -- if we have enough points, recover a point of health and increase paddle size
    if self.score > self.recoverPoints then
        -- can't go above 3 health
        self.health = math.min(3, self.health + 1)

        -- increase paddle size
        if self.paddle.size <= 3 then
            self.paddle.size = self.paddle.size + 1
            self.paddle.width = self.paddle.width + 32
        end

        -- increase recover points
        self.recoverPoints = math.min(100000, self.recoverPoints * RECOVER_RATE)

        -- play recover sound effect
        gSounds['recover']:play()
    end

    -- go to our victory screen if there are no more bricks left
    if self:checkVictory() then
        gSounds['victory']:play()

        gStateMachine:change('victory', {
            level = self.level,
            score = self.score,
            highScores = self.highScores,
            paddle = self.paddle,
            health = self.health,
            ball = self.ball,
            recoverPoints = self.recoverPoints,
            levelChanged = self.levelChanged
        })
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    if self.ball.y >= VIRTUAL_HEIGHT then
        self.health = self.health - 1
        gSounds['hurt']:play()

        -- reduce paddle size when user loses a health
        if self.paddle.size > 1 then
            self.paddle.size = self.paddle.size - 1
            self.paddle.width = self.paddle.width - 32
        end
        
        -- game ends if user has 0 health
        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                levelChanged = false,
                recoverPoints = self.recoverPoints,
                powerups = self.powerups,
                powerupEffects = self.powerupEffects,
            })
        end
    end
    
    -- if extra altBalls go beyond screen boundaries, remove them from play
    for k, altBall in pairs(self.powerupEffects['altBalls']) do
        if altBall.inPlay and altBall.y >= VIRTUAL_HEIGHT then
            altBall.inPlay = false
            self.powerupEffects['altBallCount'] = self.powerupEffects['altBallCount'] - 1
        end
    end

    -- spawn powerups that spawn based on time (keys)
    self.spawnTimer = self.spawnTimer - dt
    if self.spawnTimer <= 0 then
        -- if we have more powerups, then we will need to spawn the powerups randomly
        table.insert(self.powerups, Powerup(math.random(0, VIRTUAL_WIDTH - 16), 0, 10))
        self.spawnTimer = math.random(3, 10)
    end

    -- handle collision of powerups with paddle (user picks up powerup)
    for k, powerup in pairs(self.powerups) do
        if powerup.inPlay and self:hasCollision(powerup, self.paddle) then
            -- update how powerup is rendered
            powerup:hit()

            if powerup.powerType == 9 then
                -- spawn two new extra balls
                table.insert(self.powerupEffects['altBalls'], self:generateAltBall())
                table.insert(self.powerupEffects['altBalls'], self:generateAltBall())
                self.powerupEffects['altBallCount'] = self.powerupEffects['altBallCount'] + 2
            elseif powerup.powerType == 10 then
                -- give user one more key
                self.powerupEffects['keyCount'] = self.powerupEffects['keyCount'] + 1
            end

            -- avoid infinite collision
            break
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    -- render powerups
    for k, powerup in pairs(self.powerups) do
        powerup:render()
    end

    -- render paddle
    self.paddle:render()

    -- render main and extra balls (if any)
    self.ball:render()
    for k, altBall in pairs(self.powerupEffects['altBalls']) do
        altBall:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    Powerup.renderPowerupEffects(self.powerupEffects)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end

--[[
    PlayState collision function (for interactions between balls, paddle, powerups).
    Returns true if the bounding boxes of two objects overlap, using AABB collision.
    Takes in an `object` and a `target`.
    Assumes the following attributes: x, y, width, height.
]]
function PlayState:hasCollision(object, target)
    if object.x > target.x + target.width or target.x > object.x + object.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if object.y > target.y + target.height or target.y > object.y + object.height then
        return false
    end

    -- if the above aren't true, they're overlapping
    return true
end

--[[
    PlayState ball-paddle collision function. Called in `update(dt)`.
    When a ball hits paddle, bounce back.
    Used primarily for `self.ball`, but also recycled for any `altBall` from powerups.
]]
function PlayState:ballPaddleHandler(ball, paddle)
    if self:hasCollision(ball, paddle) then
        -- raise ball above paddle in case it goes below it, then reverse dy
        ball.y = paddle.y - ball.height
        ball.dy = -ball.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --
        -- if we hit the paddle on its left side while moving left...
        if ball.x < paddle.x + (paddle.width / 2) and paddle.dx < 0 then
            ball.dx = -50 + -(8 * (paddle.x + paddle.width / 2 - ball.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif ball.x > paddle.x + (paddle.width / 2) and paddle.dx > 0 then
            ball.dx = 50 + (8 * math.abs(paddle.x + paddle.width / 2 - ball.x))
        end

        gSounds['paddle-hit']:play()
    end
    
end

--[[
    PlayState ball-bricks collision function. Called in `update(dt)`.
    When a ball hits a brick, bounce back, update score, call `brick:hit()`.
    Used primarily for `self.ball`, but also recycled for any `altBall` from powerups.
]]
function PlayState:ballBricksHandler(ball, bricks)
    -- detect collision across all bricks with the ball
    for k, brick in pairs(bricks) do

        -- only check collision if we're in play
        if brick.inPlay and self:hasCollision(ball, brick) then

            -- handle locked bricks separately
            if brick.locked then
                if self.powerupEffects['keyCount'] > 0 then
                    self.powerupEffects['keyCount'] = self.powerupEffects['keyCount'] - 1
                    -- add to score (extra points for locked bricks scaled by level)
                    self.score = self.score + (self.level * 50)
                    goto continue
                else
                    -- bounce off locked brick as usual, but don't destroy it
                    self:ballBrickCollision(ball, brick)
                    gSounds['no-brick']:play()
                    break
                end
            end

            -- add to score (for regular, unlocked bricks)
            self.score = self.score + (brick.tier * 200 + brick.color * 25)

            ::continue::
            
            -- trigger the brick's hit function, which removes it from play, and initializes particle system and powerup spawning
            brick:hit()

            -- trigger code for ball to bounce off ball
            self:ballBrickCollision(ball, brick)

            -- spawn a powerup at random in place of the destroyed brick
            if brick.spawnPowerup then
                -- if there are more powerups that spawn when brick is destroyed, 
                -- then there is a need to add probability logic
                -- but for now breaking a brick will only give `twoBalls` powerup
                -- tbh idk what's the math behind this isn't it brickwidth/2 - 4?? but it works lol
                table.insert(self.powerups, Powerup(brick.x + brick.width / 2 - 8, brick.y, 9))
            end

            -- only allow colliding with one brick, for corners
            break
        end
    end
end

--
function PlayState:ballBrickCollision(ball, brick)
    -- collision code for bricks
    --
    -- we check to see if the opposite side of our velocity is outside of the brick;
    -- if it is, we trigger a collision on that side. else we're within the X + width of
    -- the brick and should check to see if the top or bottom edge is outside of the brick,
    -- colliding on the top or bottom accordingly 
    --

    -- left edge; only check if we're moving right, and offset the check by a couple of pixels
    -- so that flush corner hits register as Y flips, not X flips
    if ball.x + 2 < brick.x and ball.dx > 0 then
        -- flip x velocity and reset position outside of brick
        ball.dx = -ball.dx
        ball.x = brick.x - 8

    -- right edge; only check if we're moving left, and offset the check by a couple of pixels
    -- so that flush corner hits register as Y flips, not X flips
    elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
        -- flip x velocity and reset position outside of brick
        ball.dx = -ball.dx
        ball.x = brick.x + 32

    -- top edge if no X collisions, always check
    elseif ball.y < brick.y then
        -- flip y velocity and reset position outside of brick
        ball.dy = -ball.dy
        ball.y = brick.y - 8

    -- bottom edge if no X collisions or top collision, last possibility
    else
        -- flip y velocity and reset position outside of brick
        ball.dy = -ball.dy
        ball.y = brick.y + 16
    end

    -- slightly scale the y velocity to speed up the game, capping at +- 150
    if math.abs(ball.dy) < 150 then
        ball.dy = ball.dy * 1.02
    end
end

--[[
    Function that generates an additional ball when the 'add ball' powerup is collected.
    Initializes random values for the ball, but it will start from center of paddle.
]]
function PlayState:generateAltBall()
    local ball = Ball(7)
    ball.x = self.paddle.x + self.paddle.width / 2
    ball.y = self.paddle.y - ball.height
    ball.dx = math.random(-200, 200)
    ball.dy = math.random(-50, -60)
    return ball
end
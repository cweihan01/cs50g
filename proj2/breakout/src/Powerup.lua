--[[
    GD50
    Breakout Remake

    Powerup Class

    Represents a powerup which can be obtained by the user by 'catching' it
    with their paddle. Spawned randomly upon destroying a brick. Type of
    powerups spawned can be random, but currently limited to only support
    the `add ball` powerup. Powerups last till the end of each level.
]]

Powerup = Class {}

--[[
    Initializes a powerup with it's x and y coordinates, and type.
    For now, type will always be `9`, which is the `add ball` powerup.
]]
function Powerup:init(x, y, powerType)
    self.x = x
    self.y = y
    self.dy = math.random(40, 100)

    self.width = 8
    self.height = 8

    self.powerType = powerType

    -- `inPlay` checks if a powerup is currently available for user to collect,
    -- true when powerup is just initialized and false once it is collected
    self.inPlay = true

    -- `inEffect` checks if a powerup is collected and currently actively modifying the
    -- game behaviour, false when powerup is not collected or after it has been used up
    -- self.inEffect = false
end

--[[
    Moves the powerup every frame.
]]
function Powerup:update(dt)
    if self.inPlay then
        self.y = self.y + self.dy * dt
    end

    if self.y >= VIRTUAL_HEIGHT then
        self.inPlay = false
    end
end

--[[
    Renders the respective powerup to display if in play.
]]
function Powerup:render()
    if self.inPlay then
        love.graphics.draw(gTextures['main'], gFrames['powerups'][self.powerType], self.x, self.y)
    end
end

--[[
    Handles when a powerup is collected by user's paddle.
]]
function Powerup:hit()
    gSounds['powerup']:play()
    self.inPlay = false
    -- self.inEffect = true
end

--[[
    Function that initializes a list of available powerup effects.
    Called at the start of a new level.
]]
function Powerup.generatePowerupEffects()
    return {
        ['altBalls'] = {},
        ['altBallCount'] = 0,
        ['keyCount'] = 0
    }
end

--[[
    Function that resets the list of available powerup effects.
    Most effects are re-initialized to zero, but some effects will remain.
    Called when user loses a health.
]]
function Powerup.resetPowerupEffects(powerupEffects)
    powerupEffects['altBalls'] = {}
    powerupEffects['altBallCount'] = 0
    return powerupEffects
end

--[[
    Function that displays the number of powerups in effect on screen,
    given a `powerupEffects` table from PlayState or ServeState.
]]
function Powerup.renderPowerupEffects(powerupEffects)
    love.graphics.setFont(gFonts['small'])

    -- render number of extra balls
    love.graphics.draw(gTextures['main'], gFrames['powerups'][9], VIRTUAL_WIDTH - 28, 16, 0, 0.75)
    love.graphics.print(tostring(powerupEffects['altBallCount']), VIRTUAL_WIDTH - 12, 18)

    -- render number of keys
    love.graphics.draw(gTextures['main'], gFrames['powerups'][10], VIRTUAL_WIDTH - 28, 28, 0, 0.75)
    love.graphics.print(tostring(powerupEffects['keyCount']), VIRTUAL_WIDTH - 12, 30)
end

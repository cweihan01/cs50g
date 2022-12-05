--[[
    Pause State
]]

PauseState = Class { __includes = BaseState }

--[[
    Pass in current game info to PauseState
]]
function PauseState:enter(params)
    sounds['pause']:play()
    self.game = params
end

--[[
    Listens when user exits PauseState
]]
function PauseState:update(dt)
    if love.keyboard.wasPressed('space') or love.keyboard.wasPressed('return') then
        sounds['pause']:play()
        gStateMachine:change('play', self.params)
    end
end

--[[
    Renders the pause menu with the paused game in background
]]
function PauseState:render()
    -- render game as usual but frozen in previous frame
    for k, pair in pairs(self.game.pipePairs) do
        pair:render()
    end

    love.graphics.setFont(flappyFont)
    love.graphics.print('Score: ' .. tostring(self.game.score), 8, 8)

    self.game.bird:render()

    -- render pause menu
    love.graphics.setFont(mediumFont)
    love.graphics.printf('Game Paused. Press "Space" or "Enter" to resume playing.', 0, VIRTUAL_HEIGHT / 2 - 7,
        VIRTUAL_WIDTH, 'center')
end

function PauseState:exit()
end

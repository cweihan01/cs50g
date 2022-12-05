--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles with which we must try to find matching
    sets of three horizontally or vertically.
]]

Board = Class{}

function Board:init(x, y, level)
    self.x = x
    self.y = y
    self.level = level
    self.matches = {}

    self:initializeTiles()
end

function Board:initializeTiles()
    self.tiles = {}

    for tileY = 1, 8 do
        
        -- empty table that will serve as a new row
        table.insert(self.tiles, {})

        for tileX = 1, 8 do
            
            -- create a new tile at X,Y with a random color and variety

            -- this uses all tiles of 18 colors and 6 patterns (all tiles in spritesheet)
            -- table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(18), math.random(6)))

            -- this uses 8 random tiles of no pattern for testing purposes (middle 5 rows of spreadsheet)
            table.insert(self.tiles[tileY], Tile(tileX, tileY, self:generateTileColor(), self:generateTileVariety(self.level)))
        end
    end

    -- recursively initialize if:
    -- 1. matches were returned - we want to have a matchless board on start
    -- 2. there are no solutions for the board
    while self:calculateMatches() or not self:isValidBoard() do
        self:initializeTiles()
    end
end

--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color. Doesn't need to check the last tile in every row or column if the 
    last two haven't been a match.
]]
function Board:calculateMatches()
    local matches = {}

    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color

        matchNum = 1
        
        -- every horizontal tile
        for x = 2, 8 do
            
            -- if this is the same color as the one we're trying to match...
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                
                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local match = {}

                    -- go backwards from here by matchNum
                    for x2 = x - 1, x - matchNum, -1 do
                        
                        -- for shiny matches, consider entire row as a match
                        if self.tiles[y][x2].isShiny then
                            -- reset table to prevent double counting non-shiny tiles in match
                            match = {}
                            for x3 = 1, 8 do
                                table.insert(match, self.tiles[y][x3])
                            end
                            break
                        end

                        -- add each matched tile to the match
                        table.insert(match, self.tiles[y][x2])
                    end

                    -- add this match to our total matches table
                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match, since it will not be handled by the else clause above
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for x = 8, 8 - matchNum + 1, -1 do

                -- for shiny matches, consider entire row as a match
                if self.tiles[y][x].isShiny then
                    match = {}
                    for x2 = 1, 8 do
                        table.insert(match, self.tiles[y][x2])
                    end
                    break
                end

                table.insert(match, self.tiles[y][x])
            end

            table.insert(matches, match)
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}

                    for y2 = y - 1, y - matchNum, -1 do

                        -- for shiny matches, consider entire column as a match
                        if self.tiles[y2][x].isShiny then
                            -- reset table to prevent double counting non-shiny tiles in match
                            match = {}
                            for y3 = 1, 8 do
                                table.insert(match, self.tiles[y3][x])
                            end
                            break
                        end

                        table.insert(match, self.tiles[y2][x])
                    end

                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for y = 8, 8 - matchNum + 1, -1 do

                -- for shiny matches, consider entire column as a match
                if self.tiles[y][x].isShiny then
                    match = {}
                    for y2 = 1, 8 do
                        table.insert(match, self.tiles[y2][x])
                    end
                    break
                end
                
                table.insert(match, self.tiles[y][x])
            end

            table.insert(matches, match)
        end
    end

    -- store matches for later reference
    self.matches = matches

    -- return matches table if > 0, else just return false
    return #self.matches > 0 and self.matches or false
end

--[[
    Remove the matches from the Board by just setting the Tile slots within
    them to nil, then setting self.matches to nil.
]]
function Board:removeMatches()
    for k, match in pairs(self.matches) do
        for j, tile in pairs(match) do
            self.tiles[tile.gridY][tile.gridX] = nil
        end
    end

    self.matches = nil
end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do
            
            -- if our last tile was a space...
            local tile = self.tiles[y][x]
            
            if space then
                
                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then
                    
                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    -- set its prior position to nil
                    self.tiles[y][x] = nil

                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY

                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true
                
                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end

    -- create replacement tiles at the top of the screen
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

            -- if the tile is nil, we need to add a new one
            if not tile then

                -- new tile with random color and variety
                local tile = Tile(x, y, self:generateTileColor(), self:generateTileVariety(self.level))
                tile.y = -32
                self.tiles[y][x] = tile

                -- create a new tween to return for this tile to fall down
                tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                }
            end
        end
    end

    return tweens
end

--[[
    Function that checks if the current board is valid/playable.
    Considers each tile, and every possible swap for each tile.
    If no match is possible, return false.

    FIXME:
    - not sure if there is anything wrong with this code.
    - when i try to return true once a match is found (for efficiency),
      it becomes stuck in an infinite loop.
]]
function Board:isValidBoard()
    local matches = 0

    for y = 1, 8 do
        for x = 1, 8 do
            -- for each tile, store the x, y coordinates of adjacent tiles
            -- if no adjacent tile (side piece), store current tile
            local swaps = {
                ["left"] = {math.max(1, x - 1), y},
                ["right"] = {math.min(8, x + 1), y},
                ["up"] = {x, math.max(1, y - 1)},
                ["down"] = {x, math.min(8, y + 1)}
            }

            local currentTile = self.tiles[y][x]
            
            -- try all possible swaps (left, right, up, down)
            for k, swap in pairs(swaps) do
                -- store data of adjacent tile
                local swapX = swap[1]
                local swapY = swap[2]
                local swapTile = self.tiles[swapY][swapX]

                -- prevent swapping out of bounds (edge tiles)
                if swapX == currentTile.gridX and swapY == currentTile.gridY then
                    goto continue
                end

                -- make swaps
                swapTile.gridX = x
                swapTile.gridY = y
                currentTile.gridX = swapX
                currentTile.gridY = swapY

                -- swap tiles in the tiles table
                self.tiles[y][x] = swapTile
                self.tiles[swapY][swapX] = currentTile

                -- if a match can be found, add to counter
                if self:calculateMatches() then
                    matches = matches + 1
                end

                -- revert swap and prepare for next swap
                swapTile.gridX = swapX
                swapTile.gridY = swapY
                currentTile.gridX = x
                currentTile.gridY = y

                self.tiles[y][x] = currentTile
                self.tiles[swapY][swapX] = swapTile

                ::continue::
            end
        end
    end

    -- at least one match allows the board to be played
    if matches >= 1 then
        return true
    else
        return false
    end
end

--[[
    Empties a given board, setting all tiles to nil.
    Currently not used, but can be used for resetting a board
    when there are no valid matches.
]]
function Board:emptyBoard()
    for y = 1, 8 do
        for x = 1, 8 do
            self.tiles[y][x] = nil
        end
    end
end

--[[
    below helper functions generate a tile color and variety
    consider factoring this out to just a `generateNewTile` function
]]
function Board:generateTileColor()
    -- test many random colors to check if the board resets
    -- return math.random(1, 15)

    -- select 8 distinct colors
    local colors = {1, 2, 9, 10, 11, 12, 14, 17}
    return colors[math.random(1, #colors)]
end

function Board:generateTileVariety(level)
    -- probability of 1/5 of spawning a special tile
    if math.random(1, 5) == 1 then
        -- spawn a random special tile (based on current level)

        -- note that this also has a chance of spawning base tile variety
        -- this also causes a drastic change in board between first 6 levels for testing,
        -- actual implementation should only add one varieties every x levels
        return math.random(1, math.min(6, level))
    else
        -- spawn base tile variety
        return 1
    end
end

function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)
        end
    end
end
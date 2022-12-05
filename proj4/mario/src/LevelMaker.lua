--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- flags that check whether key and lock has been spawned
    local keySpawned = false
    local lockSpawned = false

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    -- last 5 tiles will be flat and empty, generated below
    for x = 1, width - 5 do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance for entire column to just be emptiness (chasm)
        if math.random(7) == 1 then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            -- generate ground layers
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 then
                -- changing this prevents blocks from being spawned in the pillar
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- chance to spawn a block
            if math.random(10) == 1 then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end

            -- spawn 1 key per level (key only spawns in the second half of map)
            if not keySpawned and x > width / 2 then
                if math.random(7) == 1 then
                    local key = GameObject {
                        texture = 'keys-and-locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = math.random(1, 4),
                        solid = false,
                        collidable = true,
                        consumable = true,

                        -- when key is collected, player is able to break block
                        onConsume = function(player, object)
                            gSounds['pickup']:play()
                            player.hasKey = true
                        end
                    }
                    table.insert(objects, key)

                    -- toggle flag to only allow one key per level
                    keySpawned = true
                end
            end
            
            -- spawn 1 lock per level (key only spawns in the second half of map)
            if not lockSpawned and x > width / 2 then
                if math.random(7) == 1 then
                    local lock = GameObject {
                        texture = 'keys-and-locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = math.random(5, 8),
                        solid = true,
                        collidable = true,
                        hit = false,

                        -- when key is collected, player is able to break lock if not already broken
                        onCollide = function(player, object)
                            if not object.hit and player.hasKey then
                                gSounds['powerup-reveal']:play()
                                player.hasKey = false
                                object.hit = true
                                
                                -- show that the lock has been unlocked by rendering a key over the lock
                                local key = GameObject {
                                    texture = 'keys-and-locks',
                                    x = object.x,
                                    y = object.y,
                                    width = 16,
                                    height = 16,
                                    frame = math.random(1, 4),
                                    solid = false,
                                    collidable = false,
                                    consumable = false
                                }
                                table.insert(objects, key)

                                -- spawn flag and flagpole to indicate end of level
                                local flag = GameObject {
                                    texture = 'flags',
                                    x = (width - 2) * TILE_SIZE + 6,
                                    y = (4 - 1) * TILE_SIZE,
                                    width = TILE_SIZE,
                                    height = TILE_SIZE,
                                    frame = math.random(1, 4),
                                    collidable = false,
                                    consumable = false
                                }
                                table.insert(objects, flag)

                                local pole = GameObject {
                                    texture = 'poles',
                                    x = (width - 2) * TILE_SIZE, -- at end of level
                                    y = (4 - 1) * TILE_SIZE,
                                    width = 16,
                                    height = 64,
                                    frame = math.random(1, 6),
                                    collidable = false,
                                    consumable = true,

                                    -- when end flag is hit ('consumed'), regenerate longer level
                                    onConsume = function(player)
                                        gSounds['pickup']:play()
                                        gStateMachine:change('play', {
                                            ['width'] = math.floor(width * 1.10),
                                            ['score'] = player.score
                                        })
                                    end
                                }
                                table.insert(objects, pole)

                            else
                                gSounds['empty-block']:play()
                            end
                        end
                    }
                    table.insert(objects, lock)

                    -- toggle flag to only allow one key per level
                    lockSpawned = true
                end
            end
        end
    end

    -- generate flat land for the last 5 tiles of each level
    -- ensures that the goal flag spawns correctly
    for x = width - 4, width do
        -- lay out the empty space
        local tileID = TILE_ID_EMPTY
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end
        
        local tileID = TILE_ID_GROUND
        -- generate ground layers
        for y = 7, height do
            table.insert(tiles[y],
                Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end


--[[
    TODO
    spawns the goal flag post only when the locked block is unlocked
    when the flag post is collided (onConsume), level should regenerate
    restart level through PlayState, passing in current score and width of map
    `onConsume` should apply to both the flag and the pole, but start off with just the pole maybe
]]
function LevelMaker.spawnGoal(width)
    
end
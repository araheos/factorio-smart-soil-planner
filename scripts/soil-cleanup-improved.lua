-- scripts/soil-cleanup-area.lua

local CropGrid = require("scripts.crop-grid")
local ModSettings = require("scripts.mod-settings")

local BLOCKING_ENTITIES = require("scripts.entity-types")

local ENABLE_DECONSTRUCTION = true

local SoilCleanup = {}

local SOIL_TYPES = {
    ["overgrowth-yumako-soil"] = true,
    ["artificial-yumako-soil"] = true,
    ["overgrowth-jellynut-soil"] = true,
    ["artificial-jellynut-soil"] = true
}

local ALLOWED_YUMAKO_TILES = {
    ["natural-yumako-soil"] = true,
    ["wetland-yumako"] = true,
    ["wetland-green-slime"] = true,
    ["wetland-light-green-slime"] = true,
    ["lowland-olive-blubber"] = true,
    ["lowland-olive-blubber-2"] = true,
    ["lowland-olive-blubber-3"] = true,
    ["lowland-brown-blubber"] = true,
    ["lowland-pale-green"] = true
}

local ALLOWED_JELLYNUT_TILES = {
    ["natural-jellynut-soil"] = true,
    ["wetland-jellynut"] = true,
    ["lowland-cream-red"] = true,
    ["lowland-red-infection"] = true,
    ["lowland-red-vein"] = true,
    ["lowland-red-vein-2"] = true,
    ["lowland-red-vein-3"] = true,
    ["lowland-red-vein-4"] = true,
    ["lowland-red-vein-dead"] = true,
    ["wetland-pink-tentacle"] = true,
    ["wetland-red-tentacle"] = true
}


local function get_natural_tile(tile)
    return tile.double_hidden_tile
        or tile.hidden_tile
        or tile.name
end


local function is_artificial_soil(tile)
    return SOIL_TYPES[tile.name] == true
end


local function is_tile_yumako_compatible(tile)
    local natural_tile = get_natural_tile(tile)
    return ALLOWED_YUMAKO_TILES[natural_tile] == true
end


local function is_tile_jellynut_compatible(tile)
    local natural_tile = get_natural_tile(tile)
    return ALLOWED_JELLYNUT_TILES[natural_tile] == true
end


-- Create a unique key for each tile position
local function tile_key(x, y)
    return x .. "," .. y
end


local function get_nearby_towers(tile)
    local pos = tile.position
    local radius = 9

    return tile.surface.find_entities_filtered({
        area = {
            {pos.x - radius, pos.y - radius},
            {pos.x + radius + 1, pos.y + radius + 1}
        },
        type = "agricultural-tower"
    })
end


-- Get all nine tiles belonging to a plot
local function get_plot_tiles(surface, plot)
    if not plot then
        return nil
    end

    local tiles = {}

    for dx = 0, 2 do
        for dy = 0, 2 do
            local tile = surface.get_tile(
                plot.x + dx,
                plot.y + dy
            )
            table.insert(tiles, tile)
        end
    end

    return tiles
end


local function is_tile_blocked(tile)
    local pos = tile.position
    local entities = tile.surface.find_entities_filtered({
        area = {
            {pos.x, pos.y},
            {pos.x + 1, pos.y + 1}
        }
    })

    for _, entity in pairs(entities) do
        if entity.valid and BLOCKING_ENTITIES[entity.type] then
            return true
        end
    end

    return false
end


local function is_plot_valid(tiles, flag_ignore_buildings)
    local yumako_tiles = 0
    local jellynut_tiles = 0
    for _, tile in pairs(tiles) do
        -- if preserve soil beneach buildings is set to true, is_tile_blocked(...) can be skipped
        if flag_ignore_buildings or not is_tile_blocked(tile) then
            if is_tile_yumako_compatible(tile) then
                yumako_tiles = yumako_tiles + 1
            elseif is_tile_jellynut_compatible(tile) then
                jellynut_tiles = jellynut_tiles + 1
            end
        end
    end

    -- if there are 9 yumako or jellynut tiles, attempt yumako planting test
    if yumako_tiles == 9 or jellynut_tiles == 9 then
        return true
    end

    return false
end


function SoilCleanup.analyze(soil_tiles, player)
    local config = ModSettings.get(player)

    local protected_tiles = {}
    local candidate_tiles = {}


    for _, tile in pairs(soil_tiles) do
        -- look for harvesting towers hearby
        local towers = get_nearby_towers(tile)


        if config.affect_tiles_outside_towers and #towers == 0 then
            local key = tile_key(
                tile.position.x,
                tile.position.y
            )
            candidate_tiles[key] = tile
        end

        -- player.print("Found " .. #towers .. " agricultural tower(s).")

        for _, tower in pairs(towers) do
            local surface = tower.surface
            local plot = CropGrid.get_plot_for_tile(tower, tile)
            
            local tiles = get_plot_tiles(surface, plot)
            -- only execute if plot is not the center tile with a tower, as this wouldn't be considered a plot
            if plot then
                if is_plot_valid(tiles, config.ignore_buildings) then
                    -- Protect all tiles in valid plots
                    for _, tile in pairs(tiles) do
                        local key = tile_key(
                            tile.position.x,
                            tile.position.y
                        )
                        protected_tiles[key] = true
                    end
                else
                    -- Mark special soil tile as candidate for removal
                    for _, tile in pairs(tiles) do
                        if is_artificial_soil(tile) then
                            local key = tile_key(
                                tile.position.x,
                                tile.position.y
                            )
                            candidate_tiles[key] = tile
                        end
                    end
                end
            end

        end
    end

    return {
        candidate_tiles = candidate_tiles,
        protected_tiles = protected_tiles,
    }
end


local function mark_soil_for_cleanup(tile, player, undo_index)
    if tile.to_be_deconstructed(player.force) then
        return nil
    end

    return tile.surface.create_entity({
        name = "deconstructible-tile-proxy",
        position = tile.position,
        force = player.force,
        player = player,
        undo_index = undo_index,
        proxy_type = "foundation"
    })
end


-- Determine which soil tiles are wasted
function SoilCleanup.process(soil_tiles, player)
    local result = SoilCleanup.analyze(soil_tiles, player)

    local wasted_tiles = {}

    --player.print("Candidate tiles: " .. table_count(result.candidate_tiles))
    --player.print("Protected tiles: " .. table_count(result.protected_tiles))


    -- Only remove soil that isn't protected
    -- by any valid plot from a selected tower.
    for key, tile in pairs(result.candidate_tiles) do
        if not result.protected_tiles[key] then
            table.insert(wasted_tiles, tile)
        end
    end

    -- Actual deconstruction
    if ENABLE_DECONSTRUCTION then
        local stack = player.undo_redo_stack
        local before = stack.get_undo_item_count()

        local undo_index = 0
        
        for _, tile in pairs(wasted_tiles) do
            if not is_tile_blocked(tile) then

                local proxy = mark_soil_for_cleanup(
                    tile,
                    player,
                    undo_index
                )
                    
                if proxy then
                    undo_index =  1
                end
            end
        end
        
        local after = stack.get_undo_item_count()
    end

    return {
        wasted_tiles = wasted_tiles
    }
end


return SoilCleanup
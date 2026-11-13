
local CropGrid = require("scripts.crop-grid")
local ModSettings = require("scripts.mod-settings")

local BLOCKING_ENTITIES = require("scripts.entity-types")

local SoilPlanner = {}

local SOIL_TYPES = {
    "overgrowth-yumako-soil",
    "artificial-yumako-soil",
    "overgrowth-jellynut-soil",
    "artificial-jellynut-soil"
}

local TILES_YUMAKO_OVERGROWTH = {
    --["natural-yumako-soil"] = true,
    --["wetland-yumako"] = true,
    ["wetland-green-slime"] = true,
    ["wetland-light-green-slime"] = true,
    ["lowland-olive-blubber"] = true,
    ["lowland-olive-blubber-2"] = true,
    ["lowland-olive-blubber-3"] = true,
    ["lowland-brown-blubber"] = true,
    ["lowland-pale-green"] = true
}

local TILES_JELLYNUT_OVERGROWTH = {
    --["natural-jellynut-soil"] = true,
    --["wetland-jellynut"] = true,
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

local TILES_YUMAKO_ARTIFICIAL = {
    ["wetland-yumako"] = true
}

local TILES_JELLYNUT_ARTIFICIAL = {
    ["wetland-jellynut"] = true
}

local TILES_YUMAKO_COMPATIBLE = {
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

local TILES_JELLYNUT_COMPATIBLE = {
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

-- Verify if any yumako soil can be placed on this biome/surface tile
local function is_tile_yumako_compatible(tile)
    local natural_tile = get_natural_tile(tile)
    return TILES_YUMAKO_COMPATIBLE[natural_tile] == true
end

-- Verify if any jellynut soil can be placed on this biome/surface tile
local function is_tile_jellynut_compatible(tile)
    local natural_tile = get_natural_tile(tile)
    return TILES_JELLYNUT_COMPATIBLE[natural_tile] == true
end

-- Create a unique key for each tile position
local function tile_key(x, y)
    return x .. "," .. y
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

-- Get all nine tiles belonging to a plot
local function get_plot_tiles(surface, plot)
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


-- Analyze all selected towers together
function SoilPlanner.analyze(towers, player)
    local config = ModSettings.get(player)

    local viable_tiles = {}
    local remaining_tiles = {}

    local valid_plots = 0
    local invalid_plots = 0

    for _, tower in pairs(towers) do
        local surface = tower.surface
        local plots = CropGrid.get_plots(tower)

        for _, plot in pairs(plots) do
            local tiles = get_plot_tiles(surface, plot)

            if is_plot_valid(tiles, config.ignore_buildings) then
                -- register all tiles in valid plots
                valid_plots = valid_plots + 1
                for _, tile in pairs(tiles) do
                    local key = tile_key(
                        tile.position.x,
                        tile.position.y
                    )
                    viable_tiles[key] = tile
                end
            else
                -- optionally fill invalid tiles with placeholder soil
                invalid_plots = invalid_plots + 1
                for _, tile in pairs(tiles) do
                    local key = tile_key(
                        tile.position.x,
                        tile.position.y
                    )
                    remaining_tiles[key] = tile
                end
            end
        end
    end

    return {
        viable_tiles = viable_tiles,
        remaining_tiles = remaining_tiles,
        valid_plots = valid_plots,
        invalid_plots = invalid_plots
    }
end


local function place_soil_ghost(tile, soil_type, player, undo_index)
    if tile.has_tile_ghost(player.force) then
        return nil
    end

    return tile.surface.create_entity({
        name = "tile-ghost",
        inner_name = soil_type,
        position = tile.position,
        force = player.force,
        player = player,
        undo_index = undo_index
    })
end


local function place_filler_tile(tile, player, undo_index)
    local config = ModSettings.get(player)
    local filler = config.placeholder_tile
    if filler == "none" then
        return nil
    end

    -- check if landfill can be placed
    if not tile.surface.can_place_entity({
        name = "tile-ghost",
        inner_name = "landfill",
        position = tile.position,
        force = player.force
    }) then
        return nil
    end
    -- attempt placing the landfill
    result = tile.surface.create_entity({
        name = "tile-ghost",
        inner_name = "landfill",
        position = tile.position,
        force = player.force,
        player = player,
        undo_index = undo_index
    })
    if filler == "landfill" then
        return result
    end

    -- check if the cover layer can be placed
    if not tile.surface.can_place_entity({
        name = "tile-ghost",
        inner_name = filler,
        position = tile.position,
        force = player.force
    }) then
        return nil
    end

    -- attempt placing the cover layer
    return tile.surface.create_entity({
        name = "tile-ghost",
        inner_name = filler,
        position = tile.position,
        force = player.force,
        player = player,
        undo_index = undo_index
    })

end


function SoilPlanner.process(towers, player)
    local result = SoilPlanner.analyze(towers, player)

    local undo_index = 0
    local created = 0

    for key, tile in pairs(result.viable_tiles) do
        local tile_name = tile.name
        local soil_type = nil

        if TILES_YUMAKO_ARTIFICIAL[tile_name] then
            soil_type = "artificial-yumako-soil"
        elseif TILES_JELLYNUT_ARTIFICIAL[tile_name] then
            soil_type = "artificial-jellynut-soil"
        elseif TILES_YUMAKO_OVERGROWTH[tile_name] then
            soil_type = "overgrowth-yumako-soil"
        elseif TILES_JELLYNUT_OVERGROWTH[tile_name] then
            soil_type = "overgrowth-jellynut-soil"
        end

        if soil_type then
            local ghost = place_soil_ghost(
                tile,
                soil_type,
                player,
                undo_index
            )
            if ghost then
                created = created + 1
                undo_index =  1
            end
        end
    end

    for key, tile in pairs(result.remaining_tiles) do
        if not result.viable_tiles[key] then
            local ghost = place_filler_tile(
                tile,
                player,
                undo_index
            )
            if ghost then
                undo_index = 1
            end
        end
    end

end

return SoilPlanner
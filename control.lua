
-- Import custom modules
local SoilCleanup = require("scripts.soil-cleanup-improved")
local SoilPlanner = require("scripts.soil-planner")

local TOOL_NAME = "smart-soil-tool"


local TOWER_NAME = "agricultural-tower"


local function cleanupEvent(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    local tiles = event.tiles

    if #tiles == 0 then
        return
    end

    local result = SoilCleanup.process(tiles, player)

    -- Highlight wasted soil in red for debugging
    for _, tile in pairs(result.wasted_tiles) do
        local x = tile.position.x
        local y = tile.position.y

        rendering.draw_rectangle({
            color = {r = 1, g = 0, b = 0, a = 0.8},
            width = 2,
            filled = false,
            left_top = {x = x, y = y},
            right_bottom = {x = x + 1, y = y + 1},
            surface = event.surface,
            players = {player},
            time_to_live = 240
        })
    end
end


local function plannerEvent(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    local towers = event.surface.find_entities_filtered({
        area = event.area,
        name = TOWER_NAME
    })
    -- player.print("Found " .. #towers .. " agricultural tower(s).")

    if #towers == 0 then
        return
    end

    SoilPlanner.process(towers, player)

end


-- Left-click drag: Plan soil
script.on_event(
    defines.events.on_player_selected_area,
    function(event)
        if event.item == TOOL_NAME then
            plannerEvent(event)
        end
    end
)

-- Right-click drag: Clean up excess soil
script.on_event(
    defines.events.on_player_reverse_selected_area,
    function(event)
        if event.item == TOOL_NAME then
            cleanupEvent(event)
        end
    end
)


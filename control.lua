
-- Import custom modules
local SoilCleanup = require("scripts.soil-cleanup-improved")
local SoilPlanner = require("scripts.soil-planner")
local ModSettings = require("scripts.mod-settings")

local TOOL_NAME = "smart-soil-tool"

local TOWER_NAME = "agricultural-tower"

local FRUIT_PER_MIN = 10


local function cleanupEvent(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    local config = ModSettings.get(player)
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

    if config.chat_feedback then
        player.print("Detected " .. #result.wasted_tiles .. " wasted tiles.")
    end
end


local function plannerEvent(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    local config = ModSettings.get(player)

    local towers = event.surface.find_entities_filtered({
        area = event.area,
        name = TOWER_NAME
    })

    if #towers == 0 then
        return
    end

    local result = SoilPlanner.process(towers, player)
    if config.chat_feedback then
        local fruit_prod = result.valid_plots * FRUIT_PER_MIN
        fruit_prod = string.format("%.2f", fruit_prod)
        fruit_prod = fruit_prod:gsub("%.?0+$", "")

        local fruit_prod_sec = fruit_prod/60
        fruit_prod_sec = string.format("%.2f", fruit_prod_sec)
        fruit_prod_sec = fruit_prod_sec:gsub("%.?0+$", "")

        player.print("Placed " .. result.placed_tiles .. " new soil tiles across " .. result.valid_plots .. " valid plots.")
        player.print("This agricultural area will produce up to " .. fruit_prod .. " fruits/min (" .. fruit_prod_sec .. " fruits/sec)")
    end

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


local ModSettings = {}

function ModSettings.get(player)
    local s = player.mod_settings

    return {
        ignore_buildings = s["smart-soil-ignore-buildings"].value,
        placeholder_tile = s["smart-soil-placeholder-tile"].value,
        affect_tiles_outside_towers = s["smart-soil-affect-tiles-outside-towers"].value,
        chat_feedback = s["smart-soil-chat-feedback"].value
    }
end

return ModSettings
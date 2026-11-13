
data:extend({
    {
        type = "selection-tool",
        name = "smart-soil-tool",
        icon = "__smart-soil-planner__/graphics/icon_56.png",
        icon_size = 56,
        stack_size = 1,
        flags = {"only-in-cursor", "spawnable"},

        select = {
            border_color = {0, 1, 0},
            cursor_box_type = "entity",
            mode = {"any-entity"},
            entity_filters = {"agricultural-tower"}
        },
        alt_select = {
            border_color = {0, 1, 0},
            cursor_box_type = "entity",
            mode = {"any-entity"},
            entity_filters = {"agricultural-tower"}
        },

        reverse_select = {
            border_color = {1, 0, 0},
            cursor_box_type = "entity",
            mode = {"any-tile"},
            tile_filters = {
                "artificial-yumako-soil",
                "overgrowth-yumako-soil",
                "artificial-jellynut-soil",
                "overgrowth-jellynut-soil"
            }
        },
        alt_reverse_select = {
            border_color = {1, 0, 0},
            cursor_box_type = "entity",
            mode = {"any-tile"},
            tile_filters = {
                "artificial-yumako-soil",
                "overgrowth-yumako-soil",
                "artificial-jellynut-soil",
                "overgrowth-jellynut-soil"
            }
        }
    },

    -- shortcut bar button
    {
        type = "shortcut",
        name = "smart-soil-shortcut",
        action = "spawn-item",
        item_to_spawn = "smart-soil-tool",

        icon = "__smart-soil-planner__/graphics/icon_56.png",
        icon_size = 56,

        small_icon = "__smart-soil-planner__/graphics/icon_24.png",
        small_icon_size = 24,

        order = "z[smart-soil-tool]"
    }
})

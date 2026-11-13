
data:extend({
    {
        type = "string-setting",
        name = "smart-soil-placeholder-tile",
        setting_type = "runtime-per-user",
        default_value = "none",
        allowed_values = {
            "none",
            "landfill",
            "stone-path",
            "concrete",
            "hazard-concrete-left",
            "hazard-concrete-right",
            "refined-concrete",
            "refined-hazard-concrete-left",
            "refined-hazard-concrete-right"
        },
        order = "a"
    }
})

data:extend({
    {
        type = "bool-setting",
        name = "smart-soil-ignore-buildings",
        setting_type = "runtime-per-user",
        default_value = false,
        order = "b"
    }
})

data:extend({
    {
        type = "bool-setting",
        name = "smart-soil-affect-tiles-outside-towers",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "c"
    }
})

data:extend({
    {
        type = "bool-setting",
        name = "smart-soil-chat-feedback",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "d"
    }
})
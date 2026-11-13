
local CropGrid = {}

local PLOT_SIZE = 3
local GRID_SIZE = 7

function CropGrid.get_plots(tower)
    local plots = {}

    -- The tower occupies the center 3x3 plot.
    -- Calculate the top-left corner of the
    -- entire 21x21 farming area.
    local center_x = tower.position.x
    local center_y = tower.position.y

    local start_x = math.floor(center_x) - 10 -- maybe replace this with 10.5?
    local start_y = math.floor(center_y) - 10

    for row = 0, GRID_SIZE - 1 do
        for col = 0, GRID_SIZE - 1 do

            -- Skip the center plot (the tower itself)
            if not (row == 3 and col == 3) then

                local x = start_x + col * PLOT_SIZE
                local y = start_y + row * PLOT_SIZE

                table.insert(plots, {
                    x = x,
                    y = y,
                    row = row,
                    col = col
                })
            end
        end
    end

    return plots
end


---@param tower LuaEntity
---@param tile LuaTile
---@return table|nil
function CropGrid.get_plot_for_tile(tower, tile)
    local x = tile.position.x
    local y = tile.position.y

    for _, plot in pairs(CropGrid.get_plots(tower)) do
        if x >= plot.x and x < plot.x + 3
           and y >= plot.y and y < plot.y + 3 then
            return plot
        end
    end

    return nil
end


return CropGrid

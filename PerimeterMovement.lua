TurtleGPS = require("TurtleGPS")
TurtleTools = require("TurtleTools")

function IsFarmTileBelow(cropOnFarm)
    local hasBlock, blockData = turtle.inspectDown()
    return hasBlock and blockData.name == cropOnFarm
end

function DefinePerimeterSize(cropOnfarm)
    local rowLength = 1
    local isRunning = true

    --Increments row and tile first, then try going to next row. returns true if sucessfull
    local function tryJumpToNextRow()
        if TurtleGPS.GetTurtleRelativePosition().rows == 1 then
            rowLength = math.abs(TurtleGPS.GetTurtleRelativePosition().rowLength)
        end

        isRunning = TurtleGPS.JumpToNextRow()

        if not IsFarmTileBelow(cropOnfarm) then
            TurtleGPS.Turn()
            TurtleGPS.Back()
            isRunning = false
            return
        end
    end


    --Only increments if it is trying to go to the next tile
    while isRunning do
        if turtle.detect() then
            tryJumpToNextRow()

            if not isRunning then
                break
            end
        end

        TurtleGPS.Forward()
        if not IsFarmTileBelow(cropOnfarm) then
            --is a gap?

            if turtle.detect() then
                --block infront, jump to next row
                TurtleGPS.Back()
                tryJumpToNextRow()
            else
                TurtleGPS.Forward()

                if not IsFarmTileBelow(cropOnfarm) then
                    --not a gap. jump to next row
                    TurtleGPS.Back()
                    TurtleGPS.Back()
                    tryJumpToNextRow()
                end
            end
        end
    end

    local Rows = TurtleGPS.GetTurtleRelativePosition().rows
    TurtleGPS.ReturnToOrigin()
    TurtleGPS.SeekContainer()

    return { Rows, rowLength,}
end

return { DefinePerimeterSize = DefinePerimeterSize}

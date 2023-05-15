TurtleGPS = require("TurtleGPS")
TurtleTools = require("TurtleTools")

OnMoveThroughPerimeter = {}

function IsFarmTileBelow()
    local hasBlock, blockData = turtle.inspectDown()
    return hasBlock and blockData.state.age ~= nil
end

function DefinePerimeterSize()
    local rowLength = 1
    local isRunning = true

    --Increments row and tile first, then try going to next row. returns true if sucessfull
    local function tryJumpToNextRow()
        if TurtleGPS.GetTurtleRelativePosition().rows == 1 then
            rowLength = math.abs(TurtleGPS.GetTurtleRelativePosition().rowLength)
        end

        isRunning = TurtleGPS.JumpToNextRow()

        if not IsFarmTileBelow() then
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
        if not IsFarmTileBelow() then
            --is a gap?

            if turtle.detect() then
                --block infront, jump to next row
                TurtleGPS.Back()
                tryJumpToNextRow()
            else
                TurtleGPS.Forward()

                if not IsFarmTileBelow() then
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

--Walks through the whole perimeter. When the given function returns true it break all loops
function WalkThroughPerimeter(beforeWalkingFunc)
    local perimeter = settings.get("farmbot.farm_data")
    local breakLoop = false

    if perimeter == nil then
        return false
    end
    local rows = perimeter[1]
    local rowTiles = perimeter[2]

    for i = 1, rows, 1 do
        for j = 1, rowTiles - 1, 1 do
            breakLoop = beforeWalkingFunc()
            TurtleGPS.Forward()
            if OnMoveThroughPerimeter[1] ~= nil then
                for _, value in ipairs(OnMoveThroughPerimeter) do
                    value()
                end

                if breakLoop then
                    return
                end
            end
        end

        beforeWalkingFunc()
        if i < rows then
            TurtleGPS.JumpToNextRow()
            if OnMoveThroughPerimeter[1] ~= nil then
                for _, value in ipairs(OnMoveThroughPerimeter) do
                    value()
                end
            end
        end
    end
end

return { DefinePerimeterSize = DefinePerimeterSize, WalkThroughPerimeter = WalkThroughPerimeter}

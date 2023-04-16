TurtleGPS = require("TurtleGPS")
TurtleTools = require("TurtleTools")

function IsFarmTileBelow(cropOnFarm)
    local hasBlock, blockData = turtle.inspectDown()
    return hasBlock and blockData.name == cropOnFarm
end

function ScanPerimeter(cropOnfarm)
    local row = 0
    local tiles = 0
    local gaps = {}
    local isRunning = true

    --Increments row and tile first, then try going to next row. returns true if sucessfull
    local function tryJumpToNextRow()
        tiles = tiles + 1

        isRunning = TurtleGPS.JumpToNextRow()

        if not IsFarmTileBelow(cropOnfarm) then
            TurtleGPS.Turn()
            TurtleGPS.Back()
            isRunning = false
            row = row + 1
            return
        end
        row = row + 1
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
        if IsFarmTileBelow(cropOnfarm) then
            tiles = tiles + 1
        else
            --is a gap?

            if turtle.detect() then
                --block infront, jump to next row
                TurtleGPS.Back()
                tryJumpToNextRow()
            else
                TurtleGPS.Forward()

                if IsFarmTileBelow(cropOnfarm) then
                    tiles = tiles + 2
                    table.insert(gaps, tiles)
                else
                    --not a gap. jump to next row
                    TurtleGPS.Back()
                    TurtleGPS.Back()
                    tryJumpToNextRow()
                end
            end
        end
    end

    --TODO add a way to return back home.
    ReturnToOrigin()

    local rowLength = tiles / row
    return { row, rowLength, tiles, gaps }
end

function SeekContainer()
    while true do
        print("Looking for a container.\n")
        local container = peripheral.wrap("back")
        if container ~= nil then
            local _, type = peripheral.getType(container)
            if type == "inventory" then
                break
            end
        end

        turtle.turnRight()
    end
end

function ReturnToOrigin()
    local turtlePos = TurtleGPS.GetTurtleRelativePosition()
    repeat TurtleGPS.TurnRight() until TurtleGPS.GetCurrentDirection() == "NORTH"
    print("Found NORTH!")
    print(turtlePos.x)
    local movesOnX = turtlePos.x - 1
    local movesOnY = math.max(turtlePos.y - 1, 1)
    print(movesOnX)
    print(movesOnY)

    for i = 1, movesOnX, 1 do
        TurtleGPS.Forward()
    end
    if movesOnY == 1 then
        SeekContainer()
    end
    TurtleGPS.TurnRight()
    for i = 1, movesOnY, 1 do
        TurtleGPS.Forward()
    end
    SeekContainer()
end

return { ScanPerimeter = ScanPerimeter }

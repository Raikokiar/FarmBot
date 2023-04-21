Rows = 0
Tiles = 0

IsGoneAwayFromOrigin = nil

TurtleTools = require("TurtleTools")

TurtlePosition = { rowLength = 0, rows = 0 }                        --> Position of the turtle relative to the origin point
Compass = { [1] = "NORTH",[2] = "EAST",[3] = "SOUTH",[4] = "WEST" } --> Cardinal direction. North is always pointing towards origin point. index 1 is always the current direction

--TODO: create an event when moving so i can print out and log to file whenever i move

--Must be executed when using GPS and everytime the bot executes. Defines where the turtle is and where north is
function AnchorGps(cropOnFarm)
    SeekContainer()

    if turtle.detect() then
        error("SetupError: Block ahead, turtle should be placed facing the farm")
    end
    turtle.turnLeft()

    if turtle.detect() then
        Compass = { [1] = "NORTH",[2] = "EAST",[3] = "SOUTH",[4] = "WEST" }
        TurtlePosition.rows = 1
        TurtlePosition.rowLength = 1
        IsGoneAwayFromOrigin = true
        TurnRight()
        return IsGoneAwayFromOrigin
    else
        TurtleTools.MoveOrRefuel(turtle.forward)

        local hasBlock, blockData = turtle.inspectDown()

        IsGoneAwayFromOrigin = hasBlock and blockData.name == cropOnFarm
        if IsGoneAwayFromOrigin then
            Compass = { [1] = "SOUTH",[2] = "WEST",[3] = "NORTH",[4] = "EAST" }
            TurtlePosition.rows = 1
            TurtlePosition.rowLength = -1
        else
            Compass = { [1] = "NORTH",[2] = "EAST",[3] = "SOUTH",[4] = "WEST" }
            TurtlePosition.rows = 1
            TurtlePosition.rowLength = 1
        end
        TurtleTools.MoveOrRefuel(turtle.back)
        TurnRight()
        return IsGoneAwayFromOrigin
    end
end

function SeekContainer()
    while true do
        print("Looking for a container.\n")
        local container = peripheral.wrap("back")
        if container ~= nil then
            local _, type = peripheral.getType(container)
            if type == "inventory" then
                return container
            end
        end
        TurnRight()
    end
end

function Forward()
    if GetCurrentDirection() == "SOUTH" then
        TurtlePosition.rows = TurtlePosition.rows + 1
        IsGoneAwayFromOrigin = not IsGoneAwayFromOrigin
        TurtleTools.MoveOrRefuel(turtle.forward)
        return
    else
        if GetCurrentDirection() == "NORTH" then
            TurtlePosition.rows = TurtlePosition.rows - 1
            IsGoneAwayFromOrigin = not IsGoneAwayFromOrigin
            TurtleTools.MoveOrRefuel(turtle.forward)
            return
        end
    end
    if GetCurrentDirection() == "EAST" then
        TurtlePosition.rowLength = TurtlePosition.rowLength + 1
    else
        if GetCurrentDirection() == "WEST" then
            TurtlePosition.rowLength = TurtlePosition.rowLength - 1
        end
    end
    TurtleTools.MoveOrRefuel(turtle.forward)
end

function Back()
    if GetCurrentDirection() == "SOUTH" then
        TurtlePosition.rows = TurtlePosition.rows - 1
        TurtleTools.MoveOrRefuel(turtle.back)
        IsGoneAwayFromOrigin = not IsGoneAwayFromOrigin
        return
    else
        if GetCurrentDirection() == "NORTH" then
            TurtlePosition.rows = TurtlePosition.rows + 1
            TurtleTools.MoveOrRefuel(turtle.back)
            IsGoneAwayFromOrigin = not IsGoneAwayFromOrigin
            return
        end
    end
    if GetCurrentDirection() == "EAST" then
        TurtlePosition.rowLength = TurtlePosition.rowLength - 1
    else
        if GetCurrentDirection() == "WEST" then
            TurtlePosition.rowLength = TurtlePosition.rowLength + 1
        end
    end
    TurtleTools.MoveOrRefuel(turtle.back)
end

function JumpToNextRow()
    TurnAway()
    if turtle.detect() then
        return false
    end

    Forward()
    TurnAway(true)
    return true
end

function TurnAway(inverse)
    if inverse then
        local direction = not IsGoneAwayFromOrigin
        if direction then
            TurnLeft()
            return
        else
            TurnRight()
            return
        end
    end
    if IsGoneAwayFromOrigin then
        TurnLeft()
    else
        TurnRight()
    end
end

function TurnLeft()
    local popElement = Compass[4]
    table.remove(Compass, 4)
    table.insert(Compass, 1, popElement)

    turtle.turnLeft()
end

function TurnRight()
    local popElement = Compass[1]
    table.remove(Compass, 1)
    table.insert(Compass, popElement)

    turtle.turnRight()
end

function ReturnToOrigin()
    local turtlePos = GetTurtleRelativePosition()
    repeat TurtleGPS.TurnRight() until TurtleGPS.GetCurrentDirection() == "NORTH"
    local movesThroughRows = math.max(turtlePos.rows - 1, 1)
    local movesOnRow = math.abs(turtlePos.rowLength) - 1

    if movesThroughRows == 1 then
        TurnAway()
    end

    for i = 1, movesOnRow, 1 do
        TurtleGPS.Forward()
        print("step")
    end
    if movesThroughRows == 1 then
        return
    end
    TurnAway(true)
    for i = 1, movesOnRow, 1 do
        TurtleGPS.Forward()
    end
end

function GetCurrentDirection()
    return Compass[1]
end

function GetTurtleRelativePosition()
    return TurtlePosition
end

return {
    AnchorGps = AnchorGps,
    SeekContainer = SeekContainer,
    Forward = Forward,
    Back = Back,
    JumpToNextRow = JumpToNextRow,
    Turn = TurnAway,
    TurnLeft = TurnLeft,
    TurnRight = TurnRight,
    ReturnToOrigin = ReturnToOrigin,
    GetCurrentDirection = GetCurrentDirection,
    GetTurtleRelativePosition = GetTurtleRelativePosition
}

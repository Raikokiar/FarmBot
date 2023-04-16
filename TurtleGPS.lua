Row = 0
Tiles = 0

IsGoneAwayFromOrigin = nil

TurtleTools = require("TurtleTools")

TurtlePosition = { x = 1, y = 1 }                                    --> Position of the turtle relative to the origin point
Compass = { [1] = "NORTH",[2] = "EAST",[3] = "SOUTH",[4] = "WEST" }  --> Cardinal direction. North is always pointing towards origin point and index 1 is always the current direction

--TODO: create an event when moving so i can print out and log to file whenever i move

--Must be executed when using GPS and everytime the bot executes. Defines where the turtle is and where north is
function AnchorGps(cropOnFarm)
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


    if turtle.detect() then
        error("SetupError: Block ahead, turtle should be placed facing the farm")
    end
    turtle.turnLeft()

    if turtle.detect() then
        IsGoneAwayFromOrigin = true
        TurnRight()
        return IsGoneAwayFromOrigin
    else
        TurtleTools.MoveOrRefuel(turtle.forward)

        local hasBlock, blockData = turtle.inspectDown()

        IsGoneAwayFromOrigin = hasBlock and blockData.name == cropOnFarm
        if IsGoneAwayFromOrigin then
            Compass = { [1] = "SOUTH",[2] = "WEST",[3] = "NORTH",[4] = "EAST" }
        end
        TurtleTools.MoveOrRefuel(turtle.back)
        TurnRight()
        return IsGoneAwayFromOrigin
    end
end

function Forward()
    if GetCurrentDirection() == "SOUTH" then
        TurtlePosition.y = TurtlePosition.y + 1
        TurtleTools.MoveOrRefuel(turtle.forward)
        return
    else
        if GetCurrentDirection() == "NORTH" then
            TurtlePosition.y = TurtlePosition.y - 1
            TurtleTools.MoveOrRefuel(turtle.forward)
            return
        end
    end
    if IsGoneAwayFromOrigin then
        TurtlePosition.x = TurtlePosition.x + 1
    else
        TurtlePosition.x = TurtlePosition.x - 1
    end
    TurtleTools.MoveOrRefuel(turtle.forward)
end

function Back()
    if GetCurrentDirection() == "SOUTH" then
        TurtlePosition.y = TurtlePosition.y - 1
        TurtleTools.MoveOrRefuel(turtle.back)
        return
    else
        if GetCurrentDirection() == "NORTH" then
            TurtlePosition.y = TurtlePosition.y + 1
            TurtleTools.MoveOrRefuel(turtle.back)
            return
        end
    end
    if IsGoneAwayFromOrigin then
        TurtlePosition.x = TurtlePosition.x - 1
    else
        TurtlePosition.x = TurtlePosition.x + 1
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

function TurnAway(flip)
    if IsGoneAwayFromOrigin then
        TurnLeft()
    else
        TurnRight()
    end

    if flip then
        IsGoneAwayFromOrigin = not IsGoneAwayFromOrigin
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

function GetCurrentDirection()
    return Compass[1]
end

function GetTurtleRelativePosition()
    return TurtlePosition
end

return {
    AnchorGps = AnchorGps,
    Forward = Forward,
    Back = Back,
    JumpToNextRow = JumpToNextRow,
    Turn = TurnAway,
    TurnLeft = TurnLeft,
    TurnRight = TurnRight,
    GetCurrentDirection = GetCurrentDirection,
    GetTurtleRelativePosition = GetTurtleRelativePosition
}

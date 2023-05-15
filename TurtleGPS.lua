Rows = 0
Tiles = 0

IsGoneAwayFromOrigin = nil

TurtleTools = require("TurtleTools")

TurtlePosition = { rowLength = 0, rows = 0 }                           --> Position of the turtle relative to the origin point
PreviousPosition = {}                                                  --> Position before ReturningHome
Compass = { [1] = "NORTH", [2] = "EAST", [3] = "SOUTH", [4] = "WEST" } --> Cardinal direction. North is always pointing towards origin point. index 1 is always the current direction
PreviousHeading = ""

OnBeforeMoving = {}
OnBeforeTurn = {}

--Must be executed when using GPS and everytime the bot executes. Defines where the turtle is and where north is
function AnchorGps()
    TurtlePosition = { rowLength = 0, rows = 0 }
    PreviousPosition = {}
    Compass = { [1] = "NORTH", [2] = "EAST", [3] = "SOUTH", [4] = "WEST" }
    PreviousHeading = ""

    SeekContainer()

    if turtle.detect() then
        error("SetupError: Block ahead, turtle should be placed facing the farm")
    end
    turtle.turnLeft()

    if turtle.detect() then
        Compass = { [1] = "NORTH", [2] = "EAST", [3] = "SOUTH", [4] = "WEST" }
        TurtlePosition.rows = 1
        TurtlePosition.rowLength = 1
        IsGoneAwayFromOrigin = true
        TurnRight()
        settings.set("farmbot.gps", { Compass, IsGoneAwayFromOrigin, TurtlePosition })
        settings.save()
        return IsGoneAwayFromOrigin
    else
        TurtleTools.MoveOrRefuel(turtle.forward)

        local hasBlock, blockData = turtle.inspectDown()

        IsGoneAwayFromOrigin = hasBlock and blockData.state.age ~= nil
        if IsGoneAwayFromOrigin then
            Compass = { [1] = "SOUTH", [2] = "WEST", [3] = "NORTH", [4] = "EAST" }
            TurtlePosition.rows = 1
            TurtlePosition.rowLength = -1
        else
            Compass = { [1] = "NORTH", [2] = "EAST", [3] = "SOUTH", [4] = "WEST" }
            TurtlePosition.rows = 1
            TurtlePosition.rowLength = 1
        end
        TurtleTools.MoveOrRefuel(turtle.back)
        TurnRight()
        settings.set("farmbot.gps", { Compass, IsGoneAwayFromOrigin, TurtlePosition })
        settings.save()
        return IsGoneAwayFromOrigin
    end
end

function SeekContainer(side, timesToSpin)
    side = side or "back"
    DebugLog("Looking for a container on " .. side .. ".\n")
    while true do
        local container = peripheral.wrap(side)
        if container ~= nil then
            local _, type = peripheral.getType(container)
            if type == "inventory" then
                return container
            end
        end

        if timesToSpin ~= nil then
            if timesToSpin == 0 then
                return nil
            end
            timesToSpin = timesToSpin - 1
        end

        if side ~= "bottom" and side ~= "top" then
            TurnRight()
        else
            return nil
        end
    end
end

function Forward()
    if GetCurrentDirection() == "SOUTH" then
        TurtlePosition.rows = TurtlePosition.rows + 1
        IsGoneAwayFromOrigin = not IsGoneAwayFromOrigin
    else
        if GetCurrentDirection() == "NORTH" then
            TurtlePosition.rows = TurtlePosition.rows - 1
            IsGoneAwayFromOrigin = not IsGoneAwayFromOrigin
        end
    end
    if GetCurrentDirection() == "EAST" then
        TurtlePosition.rowLength = TurtlePosition.rowLength + 1
    else
        if GetCurrentDirection() == "WEST" then
            TurtlePosition.rowLength = TurtlePosition.rowLength - 1
        end
    end
    if OnBeforeMoving[1] ~= nil then
        for _, func in ipairs(OnBeforeMoving) do
            func()
        end
    end
    TurtleTools.MoveOrRefuel(turtle.forward)
end

function Back()
    if GetCurrentDirection() == "SOUTH" then
        TurtlePosition.rows = TurtlePosition.rows - 1
        IsGoneAwayFromOrigin = not IsGoneAwayFromOrigin
    else
        if GetCurrentDirection() == "NORTH" then
            TurtlePosition.rows = TurtlePosition.rows + 1
            IsGoneAwayFromOrigin = not IsGoneAwayFromOrigin
        end
    end
    if GetCurrentDirection() == "EAST" then
        TurtlePosition.rowLength = TurtlePosition.rowLength - 1
    else
        if GetCurrentDirection() == "WEST" then
            TurtlePosition.rowLength = TurtlePosition.rowLength + 1
        end
    end
    if OnBeforeMoving[1] ~= nil then
        for _, func in ipairs(OnBeforeMoving) do
            func()
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

    if OnBeforeTurn[1] ~= nil then
        for _, func in ipairs(OnBeforeTurn) do
            func()
        end
    end
    turtle.turnLeft()
end

function TurnRight()
    local popElement = Compass[1]
    table.remove(Compass, 1)
    table.insert(Compass, popElement)

    if OnBeforeTurn[1] ~= nil then
        for _, func in ipairs(OnBeforeTurn) do
            func()
        end
    end
    turtle.turnRight()
end

function ReturnToOrigin()
    local turtlePos = GetTurtleRelativePosition()
    PreviousPosition = { turtlePos.rows, turtlePos.rowLength }
    PreviousHeading = GetCurrentDirection()
    local movesThroughRows = turtlePos.rows - 1
    local movesOnRow = math.abs(turtlePos.rowLength) - 1

    if movesThroughRows < 1 then
        repeat TurtleGPS.TurnRight() until TurtleGPS.GetCurrentDirection() == "EAST"
    else
        repeat TurtleGPS.TurnRight() until TurtleGPS.GetCurrentDirection() == "NORTH"
    end

    for i = 1, movesThroughRows, 1 do
        TurtleGPS.Forward()
    end

    if movesThroughRows > 0 then
        TurnAway(true)
    end
    for i = 1, movesOnRow, 1 do
        TurtleGPS.Forward()
    end
end

function ReturnToPreviousPosition()
    local rows = PreviousPosition[1] - 1
    local rowLength = math.abs(PreviousPosition[2]) - 1
    repeat TurtleGPS.TurnRight() until TurtleGPS.GetCurrentDirection() == "WEST"

    for i = 1, rowLength, 1 do
        Forward()
    end

    TurnAway()

    for i = 1, rows, 1 do
        Forward()
    end

    repeat TurtleGPS.TurnRight() until TurtleGPS.GetCurrentDirection() == PreviousHeading
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
    ReturnToPreviousPosition = ReturnToPreviousPosition,
    GetCurrentDirection = GetCurrentDirection,
    GetTurtleRelativePosition = GetTurtleRelativePosition
}

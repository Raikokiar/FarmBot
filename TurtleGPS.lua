IsGoneAwayFromOrigin = nil

local TurtleTools = require("TurtleTools")

TurtlePosition = { x = 0, y = 0 }                                      --> Position of the turtle relative to the origin point
PreviousPosition = {}                                                  --> Position before ReturningHome
Compass = { [1] = "NORTH", [2] = "EAST", [3] = "SOUTH", [4] = "WEST" } --> Cardinal direction. North is always pointing towards origin point. index 1 is always the current direction
PreviousHeading = ""

OnBeforeMoving = {}
OnBeforeTurn = {}

--Must be executed when using GPS and everytime the bot executes. Defines where the turtle is and where north is
function AnchorGps()
    TurtlePosition = { x = 0, y = 0 }
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
        else
            Compass = { [1] = "NORTH", [2] = "EAST", [3] = "SOUTH", [4] = "WEST" }
        end
        TurtleTools.MoveOrRefuel(turtle.back)
        TurnRight()
        settings.set("farmbot.gps", { Compass, IsGoneAwayFromOrigin, TurtlePosition })
        settings.save()
        return IsGoneAwayFromOrigin
    end
end

--Used for getting the position of the bot with an offset of 1, meaning: origin point = a block away from the main container
function GetPositionInFarm()
    local position = { rowLength = 0, rows = 0 }
    local x, y = 0, 0

    x = math.abs(TurtlePosition.x) + 1
    y = math.abs(TurtlePosition.y) + 1

    if TurtlePosition.x < 0 then
        x = -x
    end

    if TurtlePosition.y < 0 then
        y = -y
    end

    position.rowLength = x
    position.rows = y

    return position
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
        TurtlePosition.y = TurtlePosition.y + 1
        IsGoneAwayFromOrigin = not IsGoneAwayFromOrigin
    else
        if GetCurrentDirection() == "NORTH" then
            TurtlePosition.y = TurtlePosition.y - 1
            IsGoneAwayFromOrigin = not IsGoneAwayFromOrigin
        end
    end
    if GetCurrentDirection() == "EAST" then
        TurtlePosition.x = TurtlePosition.x + 1
    else
        if GetCurrentDirection() == "WEST" then
            TurtlePosition.x = TurtlePosition.x - 1
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
        TurtlePosition.y = TurtlePosition.y - 1
        IsGoneAwayFromOrigin = not IsGoneAwayFromOrigin
    else
        if GetCurrentDirection() == "NORTH" then
            TurtlePosition.y = TurtlePosition.y + 1
            IsGoneAwayFromOrigin = not IsGoneAwayFromOrigin
        end
    end
    if GetCurrentDirection() == "EAST" then
        TurtlePosition.x = TurtlePosition.x - 1
    else
        if GetCurrentDirection() == "WEST" then
            TurtlePosition.x = TurtlePosition.x + 1
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

--turn towards a direction which will make point - current_position == 0, 0
function TurnTowardsPoint(xFirst, point)
    point = point or { 0, 0 }
    xFirst = xFirst or false
    local originX, originY = table.unpack(point)
    local x, y = TurtlePosition.x, TurtlePosition.y
    if originX ~= 0 or originY ~= 0 and point ~= nil then
        x, y = originX - x, originY - y
    end

    --x axis (EAST/WEST). postitive/negative
    local function rotateTowardsWestOrSouth()
        local west = "WEST"
        local east = "EAST"
        if y == 0 then
            --flip so it can go towards point
            west, east = east, west
            DebugLog("swap west/east")
        end

        if x > 0 then
            repeat TurtleGPS.TurnRight() until TurtleGPS.GetCurrentDirection() == east
            return true
        else
            repeat TurtleGPS.TurnRight() until TurtleGPS.GetCurrentDirection() == west
            return true
        end
    end

    --y axis (NORTH/SOUTH). positive/negative
    local function rotateTowardsNorthOrSouth()
        local north = "NORTH"
        local south = "SOUTH"
        if originX ~= 0 or originY ~= 0 then
            if originY > TurtlePosition.y then
                --swap north and south from their places so NORTH is always pointing towards the point
                north, south = south, north
                DebugLog("swap north/south")
            end
        end

        if y > 0 then
            repeat TurtleGPS.TurnRight() until TurtleGPS.GetCurrentDirection() == north
            return true
        else
            repeat TurtleGPS.TurnRight() until TurtleGPS.GetCurrentDirection() == south
            return true
        end
    end

    if xFirst then
        --swap the orders of the call
        rotateTowardsNorthOrSouth, rotateTowardsWestOrSouth = rotateTowardsWestOrSouth, rotateTowardsNorthOrSouth
    end

    if not rotateTowardsNorthOrSouth() then
        rotateTowardsWestOrSouth()
    end


    DebugLog("facing: " .. GetCurrentDirection())
end

function ReturnToOrigin(dontSaveData)
    local turtlePos = { x = GetTurtleRelativePosition().x, y = GetTurtleRelativePosition().y }
    local heading = GetCurrentDirection()
    if not dontSaveData then
        PreviousPosition = { turtlePos.x, turtlePos.y }
        PreviousHeading = GetCurrentDirection()
    end
    local movesThroughRows = math.abs(turtlePos.y)
    local movesOnRow = math.abs(turtlePos.x)

    TurnTowardsPoint(false)

    for i = 1, movesThroughRows, 1 do
        Forward()
    end

    TurnTowardsPoint(true)

    for i = 1, movesOnRow, 1 do
        Forward()
    end
    if dontSaveData then
        return { x = turtlePos.x, y = turtlePos.y, heading = heading } --return an instance of previous Position
    end
end

function ReturnToPreviousPosition(previousPosInstance)
    --rows = x, rowLength = y
    local rows = math.abs(PreviousPosition[1])
    local rowLength = math.abs(PreviousPosition[2])
    local previousPosition = PreviousPosition
    local previousHeading = PreviousHeading

    if previousPosInstance then
        rows = math.abs(previousPosInstance.x)
        rowLength = math.abs(previousPosInstance.y)
        previousPosition = { previousPosInstance.x, previousPosInstance.y }
        previousHeading = previousPosInstance.heading
    end

    TurnTowardsPoint(true, previousPosition)
    for _ = 1, rows, 1 do
        Forward()
    end

    TurnTowardsPoint(false, previousPosition)
    for _ = 1, rowLength, 1 do
        Forward()
    end

    repeat TurnRight() until GetCurrentDirection() == previousHeading
end

function GetCurrentDirection()
    return Compass[1]
end

function GetTurtleRelativePosition()
    return TurtlePosition
end

function SetPosition(position)
    TurtlePosition = position
end

--changes the previous position making so calling return to previous position function go to that place
function SetPositionToGo(position, heading)
    PreviousPosition = position
    PreviousHeading = heading
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
    GetTurtleRelativePosition = GetTurtleRelativePosition,
    GetPositionInFarm = GetPositionInFarm,
    SetPosition = SetPosition,
    TurnTowardsPoint = TurnTowardsPoint,
    SetPositionToGo = SetPositionToGo
}

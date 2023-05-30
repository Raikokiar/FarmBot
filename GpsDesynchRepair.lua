TurtleTools = require("TurtleTools")
TurtleGPS = require("TurtleGPS")
Harvesting = require("Harvest")

function Resume()
    turtle.placeDown()

    SetPosition(settings.get("farmbot.position"))
    IsGoneAwayFromOrigin = settings.get("farmbot.origin_heading")
    Compass = settings.get("farmbot.compass")

    if settings.get("farmbot.isComposting") then
        ReturnComposting()
        return
    end

    if TurtlePosition == nil then
        RecalibrateGPS()
    end

    TurtleGPS.ReturnToOrigin()
    if not TurtleGPS.SeekContainer("front", 4) then
        TurtleGPS.ReturnToPreviousPosition()
        RecalibrateGPS()
    end
    TurtleTools.DropInventory()
    TurtleGPS.TurnRight()
    TurtleGPS.TurnRight()
end

function ReturnComposting()
    if SeekContainer("bottom") then
        turtle.up()
    end

    ReturnToOrigin()
    CompostingRoutine()
    SeekContainer("back")
    HarvestLoop()
end

function RecalibrateGPS()
    DebugLog("Unprecise GPS data detected! Seeking for origin point")
    while true do
        local hasBlock, blockData = turtle.inspectDown()

        if hasBlock and blockData.state.age ~= nil and not turtle.detect() then
            TurtleTools.MoveOrRefuel(turtle.forward)
        else
            local hasBlock, blockData = turtle.inspectDown()
            
            if not hasBlock or hasBlock and blockData.state.age == nil or not turtle.detect() then
                TurtleTools.MoveOrRefuel(turtle.back)
                if TurtleGPS.SeekContainer("back", 4) then
                    local hasBlock, blockDataData = turtle.inspectDown()
                    if hasBlock and blockDataData.state.age ~= nil then
                        TurtleGPS.AnchorGps()
                        TurtleGPS.SeekContainer("front")
                    end
                    break
                end
            end
            turtle.turnRight()
        end
    end
end

return { Resume = Resume }

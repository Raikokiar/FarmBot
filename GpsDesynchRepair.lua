TurtleTools = require("TurtleTools")
TurtleGPS = require("TurtleGPS")
Harvesting = require("Harvest")

function Resume()
    local seed = settings.get("farmbot.seeds.farming")
    TurtleTools.SelectItem(seed)
    turtle.placeDown()

    TurtlePosition = settings.get("farmbot.position")
    IsGoneAwayFromOrigin = settings.get("farmbot.origin_heading")
    Compass = settings.get("farmbot.compass")

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

function RecalibrateGPS()
    DebugLog("Unprecise GPS data detected! Seeking for origin point")
    while true do
        local hasBlock, blockData = turtle.inspectDown()

        if hasBlock and blockData.state.age ~= nil and not turtle.detect() then
            TurtleTools.MoveOrRefuel(turtle.forward)
        else
            if TurtleGPS.SeekContainer("back", 4) then
                TurtleGPS.AnchorGps(settings.get("farmbot.crops.farming"))
                HarvestLoop(true)
                break
            end
            local hasBlock, blockData = turtle.inspectDown()

            if not hasBlock or hasBlock and blockData.state.age == nil or not turtle.detect() then
                TurtleTools.MoveOrRefuel(turtle.back)
            end
            turtle.turnRight()
        end
    end
end

return { Resume = Resume }

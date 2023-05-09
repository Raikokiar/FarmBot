TurtleGPS = require("TurtleGPS")
TurtleTools = require("TurtleTools")
--FarmbotUI = require("FarmbotUI")

Rows = 0
RowTiles = 0
LOW_FUEL_THRESHOLD = 200
HarvestInterval = 1863.14

local CropOnFarm
local CropAgeOnFarm
local CropSeedOnFarm

OnMoveWhileHarvesting = {}

function IsLowOnFuel()
    if turtle.getFuelLevel() < LOW_FUEL_THRESHOLD then
        TryRefillIfLow = false
        TurtleGPS.ReturnToOrigin()

        local container = TurtleGPS.SeekContainer("top")

        if container == nil then
            TryRefillIfLow = true
            TurtleGPS.ReturnToPreviousPosition()
            return
        end

        turtle.select(16)
        for i = 1, container.size(), 1 do
            turtle.suckUp()
            if turtle.refuel(64) then
                turtle.suckUp()
                TryRefillIfLow = true
                TurtleGPS.ReturnToPreviousPosition()
                return
            else
                turtle.dropUp()
            end
        end

        error("Does not have enough fuel to keep running")
    end
end

function IsInventoryFull()
    if TurtleTools.IsFull() then
        TurtleGPS.ReturnToOrigin()

        TurtleGPS.SeekContainer("front")
        TurtleTools.DropInventory()

        TurtleGPS.ReturnToPreviousPosition()
    end
end

function HarvestLoop(immediately)
    CropOnFarm = settings.get("farmbot.crops.farming")
    CropAgeOnFarm = settings.get("farmbot.maxCropAge.farming")
    CropSeedOnFarm = settings.get("farmbot.seeds.farming")

    local perimeter = settings.get("farmbot.farm_data")
    HarvestInterval = settings.get("farmbot.harvestInterval")
    Rows = perimeter[1]
    RowTiles = perimeter[2]

    table.insert(OnMoveWhileHarvesting, IsInventoryFull)

    table.insert(OnBeforeMoving, function()
        settings.set("farmbot.position", TurtlePosition)
        settings.set("farmbot.origin_heading", IsGoneAwayFromOrigin)
        settings.save()
    end)
    table.insert(OnBeforeTurn, function()
        settings.set("farmbot.compass", Compass)
        settings.save()
    end)

    if settings.get("farmbot.is_harvesting") then
        immediately = true
    end

    while true do
        settings.set("farmbot.compass", Compass)
        settings.save()

        if OnMoveWhileHarvesting[2] == nil and TurtleGPS.SeekContainer("top") then
            table.insert(OnMoveWhileHarvesting, IsLowOnFuel)
            RepeatUntilRefilled = false
        end
        if not immediately then
            settings.set("farmbot.idle", true)
            settings.save()
            sleep(HarvestInterval)
            settings.set("farmbot.idle", false)
            settings.save()
        end

        settings.set("farmbot.is_harvesting", true)
        settings.save()
        Harvest()
        settings.set("farmbot.is_harvesting", false)
        settings.save()

        immediately = false
    end
end

function Harvest()
    local function BreakAndPlaceCrop()
        local hasBlock, blockData = turtle.inspectDown()
        if hasBlock and blockData.name == CropOnFarm and blockData.state.age == CropAgeOnFarm then
            turtle.digDown()
            if not turtle.placeDown() then
                TurtleTools.SelectItem(CropSeedOnFarm)
                turtle.placeDown()
            end
        end
    end

    for i = 1, Rows, 1 do
        for j = 1, RowTiles - 1, 1 do
            BreakAndPlaceCrop()
            TurtleGPS.Forward()
            if OnMoveWhileHarvesting[1] ~= nil then
                for _, value in ipairs(OnMoveWhileHarvesting) do
                    value()
                end
            end
        end

        BreakAndPlaceCrop()
        if i < Rows then
            TurtleGPS.JumpToNextRow()
            if OnMoveWhileHarvesting[1] ~= nil then
                for _, value in ipairs(OnMoveWhileHarvesting) do
                    value()
                end
            end
        end
    end

    --turn around and deposit items
    TurtleGPS.ReturnToOrigin()
    TurtleGPS.SeekContainer("front")

    TurtleTools.DropInventory()
    TurtleGPS.TurnLeft()
    TurtleGPS.TurnLeft()
end

return { HarvestLoop = HarvestLoop }

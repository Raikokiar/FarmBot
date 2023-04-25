TurtleGPS = require("TurtleGPS")
TurtleTools = require("TurtleTools")

Rows = 0
RowTiles = 0
LOW_FUEL_THRESHOLD = 200
HarvestInterval = 1863.14

OnMoveWhileHarvesting = {}

function IsLowOnFuel()
    if turtle.getFuelLevel() < LOW_FUEL_THRESHOLD then
        TryRefillIfLow = false
        TurtleGPS.ReturnToOrigin()

        local container = TurtleGPS.SeekContainer("top")

        if container == nil then
            TryRefillIfLow = true
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
    local perimeter = settings.get("farmbot.farm_data")
    Rows = perimeter[1]
    RowTiles = perimeter[2]
    table.insert(OnMoveWhileHarvesting, IsInventoryFull)

    while true do
        if OnMoveWhileHarvesting[2] == nil and TurtleGPS.SeekContainer("top") then
            table.insert(OnMoveWhileHarvesting, IsLowOnFuel)
            RepeatUntilRefilled = false
        end
        if not immediately then
            sleep(5)
        end
        Harvest()
        immediately = false
    end
end

function Harvest()
    local function BreakAndPlaceCrop()
        local hasBlock, blockData = turtle.inspectDown()
        if hasBlock and blockData.name == CropOnFarm and blockData.state.age == CropAgeOnFarm then
            turtle.digDown()
            if not turtle.compareDown() then
                TurtleTools.LocateItem(CropSeedOnFarm)
            end
            turtle.placeDown()
        end
    end

    for i = 1, Rows, 1 do
        for j = 1, RowTiles - 1, 1 do
            BreakAndPlaceCrop()
            TurtleGPS.Forward()
            if OnMoveWhileHarvesting[1] ~= nil then
                for index, value in ipairs(OnMoveWhileHarvesting) do
                    value()
                end
            end
        end

        BreakAndPlaceCrop()
        if i < Rows then
            TurtleGPS.JumpToNextRow()
            if OnMoveWhileHarvesting[1] ~= nil then
                for index, value in ipairs(OnMoveWhileHarvesting) do
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

TurtleGPS = require("TurtleGPS")

Rows = 0
RowTiles = 0
LOW_FUEL_THRESHOLD = 80

function HarvestLoop(immediately)
    local perimeter = settings.get("farmbot.farm_data")
    Rows = perimeter[1]
    RowTiles = perimeter[2]

    while true do
        if not immediately then
            sleep(HarvestInterval)
        end
        Harvest()
        immediately = false
    end
end

function Harvest()
    local isSeedSlotSelected = false

    local function BreakAndPlaceCrop()
        local hasBlock, blockData = turtle.inspectDown()
        if hasBlock and blockData.name == CropOnFarm and blockData.state.age == CropAgeOnFarm then
            turtle.digDown()
            if not turtle.compareDown() and not isSeedSlotSelected then
                print(CropSeedOnFarm)
                isSeedSlotSelected = TurtleTools.LocateItem(CropSeedOnFarm)
            end
            turtle.placeDown()
        end
    end

    for i = 1, Rows, 1 do
        for j = 1, RowTiles - 1, 1 do
            BreakAndPlaceCrop()
            TurtleGPS.Forward()
        end
        BreakAndPlaceCrop()
        TurtleGPS.JumpToNextRow()
    end

    --turn around and deposit items
    TurtleGPS.Turn()
    TurtleGPS.Back()
    TurtleGPS.ReturnToOrigin()
    TurtleGPS.SeekContainer()

    TurtleGPS.TurnRight()
    TurtleGPS.TurnRight()
    for i = 1, 16, 1 do
        turtle.select(i)
        turtle.drop()
    end
    TurtleGPS.TurnLeft()
    TurtleGPS.TurnLeft()
end

return { HarvestLoop = HarvestLoop}
Crops = {}

Seeds = {}

MaxCropAge = {}

HarvestInterval = 1863.14

TurtleTools = require("TurtleTools")

CURRENT_VERSION = "0.0.0"



function Start()
    if settings.get("farmbot") then
        --fetch info and start harvesting loop
        Crops = settings.get("farmbot.crops")
        Seeds = settings.get("farmbot.seeds")
        MaxCropAge = settings.get("farmbot.maxCropAge")
        GpsData = settings.get("farmbot.gps")

        if GpsData ~= nil and GpsData.isHarvesting then
            Resume()
        end

        for index, value in ipairs(Crops) do
            local hasBlock, BlockData = turtle.inspectDown()
            if hasBlock and BlockData.name == value then
                HarvestLoop()
                break
            else
                if index == Crops.maxn then
                    error("No crops underneath, please put the turtle on a corner of your farm")
                end
            end
        end
    else
        SetDefaultSetting()
    end
end

function SetDefaultSetting()
    local defaultCrops = {
        [1] = "minecraft:wheat",
        [2] = "minecraft:beetroots",
        [3] = "minecraft:potatoes",
        [4] = "minecraft:carrots"
    }

    local defaultMaxCropAge = {
        [1] = 7,
        [2] = 3,
        [3] = 7,
        [4] = 7
    }

    local defaultSeeds = {
        [1] = "minecraft:wheat_seeds",
        [2] = "minecraft:beetroot_seed",
        [3] = "minecraft:potato",
        [4] = "minecraft:carrot"
    }

    settings.define("farmbot")
    settings.set("farmbot.seeds", defaultSeeds)
    settings.set("farmbot.crops", defaultCrops)
    settings.set("farmbot.maxCropAge", defaultMaxCropAge)

    Crops = defaultCrops
    MaxCropAge = defaultMaxCropAge
    Seeds = defaultMaxCropAge

    --Temporary info printing and some other player dependent setup

    print("\nData file created, now mapping area. Please provide fuel\n")
    StartMapArea()

    settings.set("farmbot", true)
end

function HarvestLoop()
    sleep(HarvestInterval)
    Harvest()
    HarvestLoop()
end

function StartMapArea()
    local isOnRightCorner = false
    local cropOnFarm

    for index, value in ipairs(Crops) do
        local hasBlock, blockData = turtle.inspectDown()

        if not hasBlock then
            error("SetupError: No crop below. is the turtle in a retangular farm field?")
        end

        if blockData.name == value then
            cropOnFarm = value
            break
        end

        if index == Crops.maxn then
            -- Prompt the player to add the crop to the list
            error("SetupError: Block below is not in Data file. use [refer to the UI here] to add more crops")
        end
    end

    -- check if turtle is on left corner and do some setup checks
    local container = peripheral.wrap("back")
    if container == nil then
        error("SetupError: No Chest to store harvest yield. Please put a chest behind the turtle")
    end
    local _, type = peripheral.getType(container)
    if type ~= "inventory" then
        error(
            "SetupError: The block behind does not have an accessable inventory, try using different containers like barrels or chests")
    end

    if turtle.detect() then
        error("SetupError: Block ahead, turtle should be placed facing the farm")
    end
    turtle.turnLeft()

    if turtle.detect() then
        isOnRightCorner = true
    else
        TurtleTools.MoveOrRefuel(turtle.forward)

        local hasBlock, blockData = turtle.inspectDown()

        isOnRightCorner = hasBlock and blockData.name == cropOnFarm
        TurtleTools.MoveOrRefuel(turtle.back)
    end

    turtle.turnRight()
    --check for coal chest in this line
    print(isOnRightCorner)

    Perimeter = ScanPerimeter(isOnRightCorner, cropOnFarm)
    print(textutils.serialize(Perimeter))
    -- settings.set("farmbot.farm", Perimeter)
end

function ScanPerimeter(orientation, cropOnfarm)
    local row = 0
    local tiles = 0
    local Gaps = {}


    --turn towards the end of perimeter
    local function Turn(flip)
        if orientation then
            turtle.turnLeft()
        else
            turtle.turnRight()
        end

        if flip then
            orientation = not orientation
        end
    end

    local function isFarmTile()
        local hasBlock, blockData = turtle.inspectDown()
        return hasBlock and blockData.name == cropOnfarm
    end

    --TODO: tiles aren't being counted right, consequentialy amount of rows will be incorrect
    while true do
        if turtle.detect() then
            Turn()

            if turtle.detect() then
                break
                --error("end of farm. still need implementation")
            end

            TurtleTools.MoveOrRefuel(turtle.forward)

            local hasBlock, blockData = turtle.inspectDown()
            if hasBlock and blockData.name == cropOnfarm then
                --jump to next row
                row = row + 1
                Turn(true)
            else
                TurtleTools.MoveOrRefuel(turtle.back)
                break
                --error("End of farm. I think?")
            end
        end

        TurtleTools.MoveOrRefuel(turtle.forward)
        local hasBlock, blockData = turtle.inspectDown()
        if hasBlock and blockData.name == cropOnfarm then
            tiles = tiles + 1
        else
            --is a gap?
            --TODO code cleaning here, it really got confusing.

            if turtle.detect() then

                --block infront, jump to next row
                TurtleTools.MoveOrRefuel(turtle.back)
                Turn()
                if turtle.detect() then
                    break
                    --error("End of farm. implementation is required")
                end
                TurtleTools.MoveOrRefuel(turtle.forward)
                if not isFarmTile() then
                    TurtleTools.MoveOrRefuel(turtle.back)
                    break
                    -- error("end of farm. no farmfield found in the next row")
                end
                Turn(true)

                row = row + 1
            else
                TurtleTools.MoveOrRefuel(turtle.forward)
                local hasBlock, blockData = turtle.inspectDown()

                if hasBlock and blockData.name == cropOnfarm then
                    tiles = tiles + 2
                    if Gaps.maxn ~= nil then
                        Gaps[Gaps.maxn + 1] = tiles
                    end
                else
                    --not a gap. jump to next row
                    TurtleTools.MoveOrRefuel(turtle.back)
                    TurtleTools.MoveOrRefuel(turtle.back)

                    Turn()
                    if turtle.detect() then
                        break
                        -- error("End of farm. implementation is required")
                    end
                    TurtleTools.MoveOrRefuel(turtle.forward)
                    Turn(true)
                    --end of farm?
                    local hasBlock, blockData = turtle.inspectDown()
                    if not hasBlock or blockData.name ~= cropOnfarm then
                        break
                        -- error("End of farm! now this time is for real :)")
                    end
                    row = row + 1
                end
            end
        end
    end

    local rowLength = tiles / row
    return { tiles, row, rowLength, Gaps }
end

function Harvest()
    --Harvest following the pattern
end

function Resume()
    --locate itself, store items and get fuel if needed
end

Start()

TurtleTools = require("TurtleTools")
PerimeterUtils = require("PerimeterMovement")
TurtleGPS = require("TurtleGPS")
Harvesting = require("Harvest")

Crops = {}
Seeds = {}
MaxCropAge = {}

HarvestInterval = 1863.14

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
    Seeds = defaultSeeds

    --Temporary info printing and some other player dependent setup

    print("\nData file created, now mapping area. Please provide fuel\n")
    StartPerimeterScan()

    settings.set("farmbot", true)
end

function StartPerimeterScan()
    CropOnFarm = nil
    CropAgeOnFarm = nil

    for index, value in ipairs(Crops) do
        local hasBlock, blockData = turtle.inspectDown()

        if not hasBlock then
            error("SetupError: No crop below. is the turtle in a retangular farm field?")
        end
        if blockData.name == value then
            CropOnFarm = value
            CropAgeOnFarm = MaxCropAge[index]
            CropSeedOnFarm = Seeds[index]
            break
        end
        if index == Crops.maxn then
            -- Prompt the player to add the crop to the list
            error("SetupError: Block below is not in Data file. use [refer to the UI here] to add more crops")
        end
    end
    -- check if turtle is on left corner and do some setup checks
    TurtleGPS.AnchorGps(CropOnFarm)

    local perimeter = PerimeterUtils.DefinePerimeterSize(CropOnFarm)
    settings.set("farmbot.farm_data", perimeter)

    Harvesting.HarvestLoop(true)
end

Start()

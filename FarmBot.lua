PerimeterUtils = require("PerimeterMovement")
TurtleGPS = require("TurtleGPS")
Harvesting = require("Harvest")
ShutdownResume = require("GpsDesynchRepair")
--FarmbotUI = require("FarmbotUI")

Crops = {}
Seeds = {}
MaxCropAge = {}

CURRENT_VERSION = "0.0.0"


local function defineCropOnFarm()
    for index, value in ipairs(Crops) do
        local hasBlock, blockData = turtle.inspectDown()

        if not hasBlock then
            error("SetupError: No crop below. is the turtle in a retangular farm field?")
        end
        if blockData.name == value then
            settings.set("farmbot.crops.farming", value)
            settings.set("farmbot.maxCropAge.farming", MaxCropAge[index])
            settings.set("farmbot.seeds.farming", Seeds[index])
            settings.save()
            return value, MaxCropAge[index], Seeds[index]
        end
    end
    -- Prompt the player to add the crop to the list
    error("SetupError: Block below is not in Data file. use [refer to the UI here] to add more crops")
end

function Start()
    if settings.get("farmbot") then
        --fetch info and start harvesting loop
        Crops = settings.get("farmbot.crops")
        Seeds = settings.get("farmbot.seeds")
        MaxCropAge = settings.get("farmbot.maxCropAge")

        local gps = settings.get("farmbot.gps")
        Compass = gps[1]
        IsGoneAwayFromOrigin = gps[2]
        TurtlePosition = gps[3]

        if settings.get("farmbot.is_harvesting") then
            ShutdownResume.Resume()
        end

        defineCropOnFarm()
        HarvestLoop()
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
    settings.set("farmbot.harvestInterval", 1863.14)
    settings.save()

    Crops = defaultCrops
    MaxCropAge = defaultMaxCropAge
    Seeds = defaultSeeds

    --Temporary info printing and some other player dependent setup

    print("\nData file created, now mapping area. Please provide fuel\n")
    StartPerimeterScan()
end

function StartPerimeterScan()
    local cropOnFarm, _, _ = defineCropOnFarm()
    -- check if turtle is on left corner and do some setup checks
    TurtleGPS.AnchorGps(cropOnFarm)

    local perimeter = PerimeterUtils.DefinePerimeterSize(cropOnFarm)
    settings.set("farmbot.farm_data", perimeter)
    settings.set("farmbot", true)
    settings.save()

    Harvesting.HarvestLoop(true)
end

Start()
--FarmbotUI.InstantiateUI(Start)

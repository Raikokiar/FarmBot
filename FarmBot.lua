PerimeterUtils = require("PerimeterMovement")
TurtleGPS = require("TurtleGPS")
Harvesting = require("Harvest")
ShutdownResume = require("GpsDesynchRepair")
--FarmbotUI = require("FarmbotUI")

Crops = {}
Seeds = {}
MaxCropAge = {}

CURRENT_VERSION = "0.0.0"

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

        local hasBlock, blockData = turtle.inspectDown()
        if blockData.state.age ~= nil then
            HarvestLoop()
        else
            error(
            "SetupError: No crops below. Refer to https://github.com/Raikokiar/FarmBot#readme for instructions on how to setup Farmbot")
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
    settings.set("farmbot.ages", defaultMaxCropAge)
    settings.set("farmbot.harvestInterval", 1863.14)
    settings.set("farmbot.maxAging", true)
    settings.set("farmbot.growAndHarvest", true)
    settings.save()

    Crops = defaultCrops
    MaxCropAge = defaultMaxCropAge
    Seeds = defaultSeeds

    --Temporary info printing and some other player dependent setup

    print("\nData file created, now mapping area. Please provide fuel\n")
    StartPerimeterScan()
end

function StartPerimeterScan()
    -- check if turtle is on left corner and do some setup checks
    TurtleGPS.AnchorGps()

    local perimeter = PerimeterUtils.DefinePerimeterSize()
    settings.set("farmbot.farm_data", perimeter)
    settings.set("farmbot", true)
    settings.save()

    Harvesting.HarvestLoop(true)
end

Start()
--FarmbotUI.InstantiateUI(Start)

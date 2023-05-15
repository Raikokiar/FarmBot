TurtleGPS = require("TurtleGPS")
TurtleTools = require("TurtleTools")
PerimeterUtils = require("PerimeterMovement")

KnownAges = settings.get("farmbot.ages")
KnownCrops = settings.get("farmbot.crops")
KnownSeeds = settings.get("farmbot.seeds")

Rows = 0
RowTiles = 0
LOW_FUEL_THRESHOLD = 200
HarvestInterval = 1863.14

Crop = nil
Seed = nil
Age = nil

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

    table.insert(OnMoveThroughPerimeter, IsInventoryFull)

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

        if OnMoveThroughPerimeter[2] == nil and TurtleGPS.SeekContainer("top") then
            table.insert(OnMoveThroughPerimeter, IsLowOnFuel)
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

local function getIndexOf(table, obj)
    for index, value in ipairs(table) do
        if value == obj then
            return index
        end
    end
end

local function containsValue(table, valueWithin)
    for index, value in ipairs(table) do
        if value == valueWithin then
            return true, index
        end
    end
    return false
end

local function findCropOfSeed(cropBeforeBreaking)
    if cropBeforeBreaking ~= nil and cropBeforeBreaking.name ~= Crop then
        --look for crop in knownCrops list
        local hasValue, index = containsValue(KnownCrops, cropBeforeBreaking.name)
        if not hasValue then
            --Look for correspoding seed for the crop
            DebugLog("Not in list!")
            for i = 1, INVENTORY_SIZE, 1 do
                if turtle.getItemCount(i) > 0 then
                    turtle.select(i)
                end
                local item = turtle.getItemDetail()
                local hasPlaced, _ = turtle.placeDown()

                if hasPlaced then
                    local hasBlock, blockData = turtle.inspectDown()
                    if hasBlock and blockData.name == cropBeforeBreaking.name then
                        Crop = blockData.name
                        table.insert(KnownCrops, Crop)
                        Seed = item.name
                        table.insert(KnownSeeds, Seed)
                        settings.set("farmbot.crops", KnownCrops)
                        settings.set("farmbot.seeds", KnownSeeds)
                        settings.save()
                        Age = nil
                    else
                        turtle.digDown()
                    end
                end
            end
            DebugLog(Crop)
        else
            Crop = cropBeforeBreaking.name
            Seed = KnownSeeds[index]
            if index <= table.maxn(KnownAges) then
                Age = KnownAges[index]
            else
                Age = nil
            end
        end
    end
end

function Harvest()
    KnownAges = settings.get("farmbot.ages")
    KnownCrops = settings.get("farmbot.crops")
    KnownSeeds = settings.get("farmbot.seeds")

    Crop = nil
    Seed = nil
    Age = nil

    local function breakAndPlaceCrop()
        local hasBlock, originalBlockData = turtle.inspectDown()
        if hasBlock and originalBlockData.state.age ~= nil then
            if Age ~= nil then
                if Age == originalBlockData.state.age then
                    turtle.digDown()
                end
            else
                turtle.digDown()
            end
            findCropOfSeed(originalBlockData)
        end

        if Seed == nil and hasBlock then
            printError("Couldn't find seed for " .. originalBlockData.name)
        else
            if turtle.getItemCount() < 1 or turtle.getItemDetail().name ~= Seed then
                TurtleTools.SelectItem(Seed)
            end
            turtle.placeDown()
        end
    end


    PerimeterUtils.WalkThroughPerimeter(breakAndPlaceCrop)

    --turn around and deposit items
    TurtleGPS.ReturnToOrigin()

    CompostingRoutine()
    TurtleGPS.SeekContainer("front")
    TurtleTools.DropInventory()
    TurtleGPS.TurnLeft()
    TurtleGPS.TurnLeft()
end

local function boneMealCrop()
    local isBoneMealSelected = TurtleTools.SelectItem("minecraft:bone_meal")
    if isBoneMealSelected then
        local canPlace, reason = turtle.placeDown()
        while canPlace do
            canPlace, reason = turtle.placeDown()
        end

        return reason
    end

    return "No bone meal left"
end

function CompostingRoutine()
    local knownSeeds = settings.get("farmbot.seeds")
    local isMaxAgingEnabled = settings.get("farmbot.maxAging")
    local isGrowAndHarvestEnabled = settings.get("farmbot.growAndHarvest")

    if isMaxAgingEnabled or isGrowAndHarvestEnabled then
        if not SeekContainer("back", 4) then
            error("Expected to be at origin point while composting")
        end

        TurnRight()

        settings.set("farmbot.isComposting", true)
        settings.save()
        turtle.forward()

        local hasBlock, blockData = turtle.inspectDown()
        if hasBlock and blockData.name == "minecraft:composter" then
            for i = 1, INVENTORY_SIZE, 1 do
                if turtle.getItemCount(i) > 0 then
                    turtle.select(i)
                end

                local item = turtle.getItemDetail()
                if item ~= nil and containsValue(knownSeeds, item.name) then
                    --Bot can get stuck in this loop. needs timeout
                    while true do
                        turtle.dropDown()
                        if turtle.getItemCount() < 1 then
                            break
                        end
                    end
                end
            end

            --Go to bone meal storage (or not)
            if turtle.detect() then
                turtle.back()
                return
            end
            turtle.forward()
            if turtle.detectDown() then
                turtle.back()
                turtle.back()
                return
            end
            turtle.down()
            local container = SeekContainer("bottom")
            if not container then
                turtle.up()
                turtle.back()
                turtle.back()
                return
            end


            for _ = 1, INVENTORY_SIZE, 1 do
                if not turtle.suckDown() then
                    break
                end
            end

            turtle.up()
            turtle.back()
            turtle.back()
            TurnLeft()
        else
            --TODO: change link to actual tutorial
            print(
                "No composter found. Go to https://github.com/Raikokiar/FarmBot#readme for more information about auto-composting and how to setup")
            settings.set("farmbot.maxAging", false)
            settings.set("farmbot.growAndHarvest", false)
            settings.save()
            turtle.back()
            TurnLeft()
            return
        end
    end

    if table.maxn(settings.get("farmbot.crops")) > table.maxn(settings.get("farmbot.ages")) then
        MaxAging()
    else
        GrowAndHarvest()
    end
end

function MaxAging()
    DebugLog("Beggining to max age")
    local knownCrops = settings.get("farmbot.crops")
    local knownAges = settings.get("farmbot.ages")
    local ageListMaxn = table.maxn(settings.get("farmbot.ages"))
    local unknownCropAges = table.maxn(knownCrops) - ageListMaxn
    local AgelessCrops = {}

    if unknownCropAges < 1 then
        return
    end


    local knownCropsMaxn = table.maxn(knownCrops)
    --subtracted by one so index doesn't start at knownCropsMaxn + 1
    for i = knownCropsMaxn - 1, knownCropsMaxn + unknownCropAges, 1 do
        if i <= knownCropsMaxn then
            table.insert(AgelessCrops, knownCrops[i])
        end
    end

    local function getTrueTableSize(taeble)
        local objectsCount = 0

        for _, value in ipairs(taeble) do
            if value then
                objectsCount = objectsCount + 1
            end
        end

        return objectsCount
    end

    local function IdentifyMaxAge()
        local hasBlock, blockData = turtle.inspectDown()
        if hasBlock and containsValue(AgelessCrops, blockData.name) then
            local reason = boneMealCrop()

            if reason == "Cannot place item here" then
                _, blockData = turtle.inspectDown()
                local cropAge = blockData.state.age
                local index = getIndexOf(knownCrops, blockData.name)
                table.insert(knownAges, index, cropAge)
                table.remove(AgelessCrops, getIndexOf(AgelessCrops, blockData.name))

                if knownCropsMaxn - getTrueTableSize(knownAges) < 1 then
                    return true
                end
            else
                if reason == "No bone meal left" then
                    return true
                end
            end
        end
    end
    PerimeterUtils.WalkThroughPerimeter(IdentifyMaxAge)
    settings.set("farmbot.ages", knownAges)
    settings.save()

    TurtleGPS.ReturnToOrigin()
end

function GrowAndHarvest()
    DebugLog("Growing and harvesting")

    KnownAges = settings.get("farmbot.ages")
    KnownCrops = settings.get("farmbot.crops")
    KnownSeeds = settings.get("farmbot.seeds")

    Crop = nil
    Seed = nil
    Age = nil

    local function boneMealHarvesting()
        local hasBlock, blockData = turtle.inspectDown()
        local reason = boneMealCrop()
        if reason == "No bone meal left" then
            return true
        end


        if hasBlock then
            turtle.digDown()
        end

        findCropOfSeed(blockData)

        if Seed == nil and hasBlock then
            printError("Couldn't find seed for " .. blockData.name)
        else
            if turtle.getItemCount() < 1 or turtle.getItemDetail().name ~= Seed then
                TurtleTools.SelectItem(Seed)
            end
            turtle.placeDown()
        end
    end

    PerimeterUtils.WalkThroughPerimeter(boneMealHarvesting)
    TurtleGPS.ReturnToOrigin()
end

return { HarvestLoop = HarvestLoop }

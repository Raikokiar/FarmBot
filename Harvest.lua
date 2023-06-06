TurtleGPS = require("TurtleGPS")
TurtleTools = require("TurtleTools")
PerimeterUtils = require("PerimeterMovement")
local TableUtils = require("TableUtils")

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
        DebugLog("Low on fuel!")
        TryRefillIfLow = false
        local previousData = TurtleGPS.ReturnToOrigin(true)

        local container = TurtleGPS.SeekContainer("top")

        if container == nil then
            TryRefillIfLow = true
            TurtleGPS.ReturnToPreviousPosition(previousData)
            return
        end

        local function getFuel()
            for i = 1, container.size(), 1 do
                turtle.suckUp()
                if turtle.refuel(64) then
                    turtle.suckUp()
                    TryRefillIfLow = true
                    TurtleGPS.ReturnToPreviousPosition(previousData)
                    return true
                else
                    turtle.dropUp()
                end
            end
            return false
        end

        turtle.select(TurtleTools.FindEmptySlot())
        if getFuel() then
            return
        end

        printError(
            "\n\nTurtle is running low on fuel. all operations have been stopped until fuel is provided on the chest above\n")
        while true do
            if getFuel() then
                break
            end
        end
    end
end

function IsInventoryFull()
    if not TurtleTools.FindEmptySlot() then
        DebugLog("Inventory is full!")
        local previousData = TurtleGPS.ReturnToOrigin(true)

        if settings.get("farmbot.growAndHarvest") then
            CompostingRoutine(true)
        end
        SeekContainer("front")
        DropInventory()

        if not TurtleTools.FindEmptySlot() then
            printError("Output chest is full, idling until it's fixed, please type anything to resume")
            read()
        end

        TurtleGPS.ReturnToPreviousPosition(previousData)
    end
end

function HarvestLoop(immediately)
    local perimeter = settings.get("farmbot.farm_data")
    HarvestInterval = settings.get("farmbot.harvestInterval")
    Rows = perimeter[1]
    RowTiles = perimeter[2]

    table.insert(OnMoveThroughPerimeter, IsInventoryFull)

    table.insert(OnBeforeMoving, function()
        settings.set("farmbot.position", GetTurtleRelativePosition())
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
        settings.set("farmbot.position", GetTurtleRelativePosition())
        settings.set("farmbot.origin_heading", IsGoneAwayFromOrigin)
        settings.save()

        if TurtleGPS.SeekContainer("top") then
            table.insert(OnMoveThroughPerimeter, 2, IsLowOnFuel)
            RepeatUntilRefilled = false
        end
        if not immediately then
            PersistentTimer()
        end

        settings.set("farmbot.is_harvesting", true)
        settings.save()
        Harvest()
        settings.set("farmbot.is_harvesting", false)
        settings.save()

        immediately = false
    end
end

function PersistentTimer()
    local timeToSleep = settings.get("farmbot.sleepTimer") or HarvestInterval / 60

    while timeToSleep > 0 do
        PrintingMethod("\n\n\n\n\n\n\n\n\n\n\n Time Remaining: " .. math.floor(timeToSleep) .. " Minute(s)")
        sleep(60)
        timeToSleep = timeToSleep - 1

        --Calculate time elapsed and convert it into minutes
        local sleepTimer = (HarvestInterval - (HarvestInterval - timeToSleep * 60)) / 60
        settings.set("farmbot.sleepTimer", sleepTimer)
        settings.save()
    end
    settings.set("farmbot.sleepTimer", HarvestInterval / 60)
    settings.save()
end

local function findCropOfSeed(cropBeforeBreaking)
    if cropBeforeBreaking ~= nil and cropBeforeBreaking.name ~= Crop then
        --look for crop in knownCrops list
        local hasValue, index = TableContainsValue(KnownCrops, cropBeforeBreaking.name)
        if not hasValue then
            --Look for correspoding seed for the crop
            DebugLog("Not in list!")
            for i = 1, INVENTORY_SIZE, 1 do
                if turtle.getItemCount(i) > 0 then
                    turtle.select(i)

                    local item = turtle.getItemDetail()

                    if item.name ~= "minecraft:bone_meal" then
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
    DebugLog("Starting to harvest")
    KnownAges = settings.get("farmbot.ages")
    KnownCrops = settings.get("farmbot.crops")
    KnownSeeds = settings.get("farmbot.seeds")

    Crop = nil
    Seed = nil
    Age = nil

    local function breakAndPlaceCrop()
        local hasBlock, originalBlockData = turtle.inspectDown()
        if hasBlock and originalBlockData.state.age ~= nil then
            turtle.select(1) -- selects the first slot so items will stack normally
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

    --Compost if needed and deposit items
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

function CompostingRoutine(ignoreRoutine)
    DebugLog("Starting composting routine")
    local knownSeeds = settings.get("farmbot.seeds")
    local isMaxAgingEnabled = settings.get("farmbot.maxAging")
    local isGrowAndHarvestEnabled = settings.get("farmbot.growAndHarvest")

    local function incorrectSetup()
        printError(
            "Incorrect composting setup found. Go to https://github.com/Raikokiar/FarmBot#setup-rules for more information about auto-composting and how to set it up")
        settings.set("farmbot.maxAging", false)
        settings.set("farmbot.growAndHarvest", false)
        settings.save()
        ReturnToOrigin()
        settings.set("farmbot.isComposting", false)
        settings.save()
    end

    if isMaxAgingEnabled or isGrowAndHarvestEnabled then
        if not SeekContainer("back", 4) then
            error("Expected to be at origin point while composting")
        end

        while GetCurrentDirection() ~= "NORTH" do
            TurnRight()
        end

        settings.set("farmbot.isComposting", true)
        settings.save()
        TurtleGPS.Forward()

        local hasBlock, blockData = turtle.inspectDown()
        local getDetailedInfo = not settings.get("farmbot.compostVegetables")
        if hasBlock and blockData.name == "minecraft:composter" then
            for i = 1, INVENTORY_SIZE, 1 do
                if turtle.getItemCount(i) > 0 then
                    turtle.select(i)
                end

                local item = turtle.getItemDetail(i, getDetailedInfo)
                if item ~= nil and TableContainsValue(knownSeeds, item.name) then
                    if getDetailedInfo and (not item.tags["forge:vegetables"] and not item.tags["c:vegetables"] and not item.tags["c:foods"]) or not getDetailedInfo then
                        --Bot can get stuck in this loop. needs timeout
                        while true do
                            turtle.dropDown()
                            if turtle.getItemCount() < 1 or turtle.getItemDetail().name == "minecraft:bone_meal" then
                                break
                            end
                        end
                    end
                end
            end

            --Go to bone meal storage (or not)
            if turtle.detect() then
                incorrectSetup()
                return false
            end
            TurtleGPS.Forward()
            if turtle.detectDown() then
                incorrectSetup()
                return false
            end
            turtle.down()
            local container = SeekContainer("bottom")
            if not container then
                turtle.up()
                incorrectSetup()
                return false
            end


            for _ = 1, INVENTORY_SIZE, 1 do
                if not turtle.suckDown() then
                    break
                end
            end

            turtle.up()
            TurtleGPS.ReturnToOrigin()
            SeekContainer("back")
        else
            incorrectSetup()
            return false
        end
    end

    settings.set("farmbot.isComposting", false)
    if not ignoreRoutine then
        settings.set("farmbot.is_harvesting", true)
        settings.save()
        if table.maxn(settings.get("farmbot.crops")) > table.maxn(settings.get("farmbot.ages")) then
            MaxAging()
        else
            GrowAndHarvest()
        end
        settings.set("farmbot.is_harvesting", false)
        settings.save()
    end
    return true
end

function MaxAging()
    DebugLog("Beginning to max age")
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

    local function IdentifyMaxAge()
        local hasBlock, blockData = turtle.inspectDown()
        if hasBlock and TableContainsValue(AgelessCrops, blockData.name) then
            local reason = boneMealCrop()

            if reason == "Cannot place item here" then
                _, blockData = turtle.inspectDown()
                local cropAge = blockData.state.age
                local index = GetIndexOf(knownCrops, blockData.name)
                table.insert(knownAges, index, cropAge)
                table.remove(AgelessCrops, GetIndexOf(AgelessCrops, blockData.name))

                if knownCropsMaxn - GetTrueTableSize(knownAges) < 1 then
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
    CompostingRoutine(true)
end

return { HarvestLoop = HarvestLoop }

--TurtleTools 1.0.0 by Raikokiar
local tableUtils = require("TableUtils")

INVENTORY_SIZE = 16

LOW_FUEL_THRESHOLD = nil
RepeatUntilRefilled = true
TryRefillIfLow = true

ItemDropBlacklist = {}

PrintingMethod = print

function MoveOrRefuel(command)
    if turtle.getFuelLevel() >= LOW_FUEL_THRESHOLD then
        return command()
    else
        while true do
            if TryRefillIfLow then
                DebugLog("Low on fuel.\n Refueling...")
                for i = 1, INVENTORY_SIZE, 1 do
                    if turtle.getItemCount(i) > 0 then
                        turtle.select(i)
                    end

                    if turtle.refuel() then
                        DebugLog("Refilled successfully")
                        return command()
                    end
                end
            end
            if not RepeatUntilRefilled then
                break
            end
        end
        return command()
    end
end

--Locate an item by the minespace
function SelectItem(itemName)
    for i = 1, INVENTORY_SIZE, 1 do
        if (turtle.getItemDetail(i) ~= nil and itemName == turtle.getItemDetail(i).name) then
            turtle.select(i)
            return true
        end
    end

    return false
end

--- check if there's any empty slots
function IsFull()
    for i = 1, INVENTORY_SIZE, 1 do
        if turtle.getItemCount(i) <= 0 then
            return false
        end
    end

    return true
end

function DropInventory()
    local hasBlacklist = table.maxn(ItemDropBlacklist) > 0
    for i = 1, 16, 1 do
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)
        end
        if not turtle.refuel(0) then
            if hasBlacklist and turtle.getItemCount() > 0 then
                if not TableContainsValue(ItemDropBlacklist, turtle.getItemDetail().name) then
                    turtle.drop()
                end
            else
                turtle.drop()
            end
        end
    end
end

function DebugLog(...)
    if PrintingMethod ~= nil then
        PrintingMethod(...)
    end
end

--Add item to not be drop when dropping inveotry
function AddItemToBlacklist(itemID)
    table.insert(ItemDropBlacklist, itemID)
end

function SetPrintingMethod(method)
    PrintingMethod = method
end

return {
    SelectItem = SelectItem,
    MoveOrRefuel = MoveOrRefuel,
    IsFull = IsFull,
    DropInventory = DropInventory,
    SetPrintingMethod = SetPrintingMethod,
    AddItemToBlacklist = AddItemToBlacklist
}

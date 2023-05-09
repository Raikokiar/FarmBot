--TurtleTools 1.0.0 by Raikokiar

INVENTORY_SIZE = 16

LOW_FUEL_THRESHOLD = nil
RepeatUntilRefilled = true
TryRefillIfLow = true

PrintingMethod = print

function MoveOrRefuel(command)
    if turtle.getFuelLevel() >= LOW_FUEL_THRESHOLD then
        return command()
    else
        while true do
            if TryRefillIfLow then
                DebugLog("Low on fuel.\n Refueling...")
                for i = 1, INVENTORY_SIZE, 1 do
                    turtle.select(i)

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
    for i = 1, 16, 1 do
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)
        end
        if not turtle.refuel(0) then
            turtle.drop()
        end
    end
end

function DebugLog(...)
    if PrintingMethod ~= nil then
        PrintingMethod(...)
    end
end

function SetPrintingMethod(method)
    PrintingMethod = method
end

return { SelectItem = SelectItem, MoveOrRefuel = MoveOrRefuel, IsFull = IsFull, DropInventory = DropInventory, SetPrintingMethod = SetPrintingMethod }

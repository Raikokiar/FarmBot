--TurtleTools 1.0.0 by Raikokiar

INVENTORY_SIZE = 16

LOW_FUEL_THRESHOLD = nil
RepeatUntilRefilled = true
TryRefillIfLow = true

function MoveOrRefuel(command)
    if turtle.getFuelLevel() >= LOW_FUEL_THRESHOLD then
        return command()
    else
        while true do
            if TryRefillIfLow then
                print("Low on fuel.\n Refueling...")
                for i = 1, INVENTORY_SIZE, 1 do
                    turtle.select(i)

                    if turtle.refuel() then
                        print("Refilled successfully")
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
function LocateItem(itemName)
    for i = 1, INVENTORY_SIZE, 1 do
        turtle.select(i)

        if (turtle.getItemDetail() ~= nil and itemName == turtle.getItemDetail().name) then
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
        turtle.select(i)
        if not turtle.refuel(0) then
            turtle.drop()
        end
    end
end

return { LocateItem = LocateItem, MoveOrRefuel = MoveOrRefuel, IsFull = IsFull, DropInventory = DropInventory }

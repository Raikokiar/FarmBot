--TurtleTools 1.0.0 by Raikokiar

INVENTORY_SIZE = 16
LOW_FUEL_THRESHOLD = 200


function MoveOrRefuel(command)
    if turtle.getFuelLevel() >= LOW_FUEL_THRESHOLD then
        return command()
    else
        print("Low on fuel.\n Refueling...")
        for i = 1, INVENTORY_SIZE, 1 do
            turtle.select(i)

            if turtle.refuel() then
                print("Refilled successfully")
                return command()
            end
        end

        print("Couldn't refuel, please refuel so I can get back to operating\n")
        return false
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

return { LocateItem = LocateItem, MoveOrRefuel = MoveOrRefuel, IsFull = IsFull }

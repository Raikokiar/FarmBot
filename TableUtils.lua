function GetTrueTableSize(taeble)
    local objectsCount = 0

    for _, value in ipairs(taeble) do
        if value then
            objectsCount = objectsCount + 1
        end
    end

    return objectsCount
end


function GetIndexOf(taeble, obj)
    for index, value in ipairs(taeble) do
        if value == obj then
            return index
        end
    end
end

function TableContainsValue(taeble, valueWithin)
    for index, value in ipairs(taeble) do
        if value == valueWithin then
            return true, index
        end
    end
    return false
end

return {
    getTrueTableSize = GetTrueTableSize,
    getIndexOf = GetIndexOf,
    containsValue = TableContainsValue
}
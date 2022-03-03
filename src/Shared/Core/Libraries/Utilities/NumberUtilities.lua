local NumberUtilities = {}

-- Returns the sum of the vararg numbers.
function NumberUtilities.Sum(...: number) : number

    local sum: number = 0

    for _, number: number in next, {...} do
        if typeof(number) == "number" then
            sum += number
        end
    end

    return sum
end

return NumberUtilities

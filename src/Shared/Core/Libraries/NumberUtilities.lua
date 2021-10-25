-- Variables
local numberUtilitiesLibrary = {}
numberUtilitiesLibrary.E = 2.7182818284590

-- Methods
function numberUtilitiesLibrary.Lerp(minimum, maximum, alpha)
	return minimum + (maximum - minimum)*alpha
end


function numberUtilitiesLibrary.InverseLerp(minimum, maximum, number)
	return (number - minimum)/(maximum - minimum)
end


function numberUtilitiesLibrary.GetEnforcedPrecisionString(number, precision)
    if number%1 > 0 then return tostring(math.floor(number*10^precision)/10^precision) end
    return tostring(number).."."..("0"):rep(precision)				
end


--
return numberUtilitiesLibrary
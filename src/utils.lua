-- -------------------------------------------------------------------------- --
--                        Utilities / Helper Functions                        --
-- -------------------------------------------------------------------------- --

UTIL = {}

---@param v number
---@param min number
---@param max number
---@return number
function UTIL.Clamp(v, min, max)
	return v < min and min or v > max and max or v
end

---@param a number
---@param b number
---@param t number
---@return number
function Lerp(a, b, t)
	return a + (b - a) * t
end

local DIGITS_PRECISION_TOLERANCY = 0.01
local lerp = 0
function UTIL.LerpOptimized(a, b, t)
	lerp = Lerp(a, b, t)

	if b < 0 then
		-- if (-v < -b) && (-v > -b) - 0.01
		if lerp < b and lerp > b - DIGITS_PRECISION_TOLERANCY then
			return b

		-- if (-v > -b) && (-v < -b) + 0.01
		elseif lerp > b and lerp < b + DIGITS_PRECISION_TOLERANCY then
			return b
		end
	--
	elseif b > 0 then
		-- if (v < b) && (v > b) - 0.01
		if lerp < b and lerp > b - DIGITS_PRECISION_TOLERANCY then
			return b

		-- if (v > b) && (v < b) + 0.01
		elseif lerp > b and lerp < b + DIGITS_PRECISION_TOLERANCY then
			return b
		end
	end

	return lerp
end

---@param radians number
---@return number
function UTIL.FixRadians(radians)
	while radians > math.pi do
		radians = radians - math.pi * 2
	end
	while radians < -math.pi do
		radians = radians + math.pi * 2
	end
	return radians
end

---@param pixel number
---@param size "width"|"height"
---@return number
function UTIL.PixelToNormalized(pixel, size)
	local screenWidth, screenHeight = GetScreenResolution()
	return pixel / (size == "width" and screenWidth or screenHeight)
end

local prevHealth = 0
---@param ped integer
---@return number
function UTIL.PedGetDamageValueFromHit(ped)
	local tempPrevHealth = prevHealth
	prevHealth = PedGetHealth(ped)
	return tempPrevHealth - prevHealth
end

---@param num number
---@return number
function UTIL.RoundNumberMax2DigitAfterComma(num)
	local roundedNum = tonumber(string.format("%.2f", num)) --[[@as number]]
	local roundedNum2 = math.floor(roundedNum)
	return roundedNum == roundedNum2 and roundedNum2 or roundedNum
end

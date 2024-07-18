for _, filename in ipairs({ "utils", "UI/base/Text", "UI/base/Texture" }) do
	LoadScript("src/" .. filename .. ".lua")
end

-- -------------------------------------------------------------------------- --
--                                    Types                                   --
-- -------------------------------------------------------------------------- --

---@alias HitDirection_Widget { weaponId: integer, hitDamage: number, startTime: number }

---@alias HitDirection_ActivationOptions { enableOnFirstPerson: boolean, enableOnThirdPerson: boolean }
---@alias HitDirection_WidgetOptions { imgPath: string, heightNormalized: number, usePixelUnit: boolean, heightInPixel: number }
---@alias HitDirection_Options { centerOffset: ArrayOfNumbers2D, radius: ArrayOfNumbers2D, timeout: number }
---@alias HitDirection_TextOptions { show: boolean, bold: boolean, color: ArrayOfNumbers4D, font: string, italic: boolean, scale: number, enableOutline: boolean, outline: ArrayOfNumbers3D, enableShadow: boolean, shadow: ArrayOfNumbers3D }

-- -------------------------------------------------------------------------- --
--                            Attributes & Methods                            --
-- -------------------------------------------------------------------------- --

---@class HitDirection
---@field private __index HitDirection
---@field private _isSimpleFirstPersonInstalled boolean
---@field private _isSimpleCustomThirdPersonInstalled boolean
---@field private _enableOnFirstPerson boolean
---@field private _enableOnThirdPerson boolean
---@field yaw number The value is obtained from main camera mod (Simple FP or Simple Custom TP), in radians.
---@field textInstance Text
---@field textureInstance Texture
---@field widgets HitDirection_Widget[]
---@field centerOffsetPos2d ArrayOfNumbers2D
---@field radius2d ArrayOfNumbers2D
---@field timeout number
---@field showText boolean
HitDirection = {}
HitDirection.__index = HitDirection

-- -------------------------------------------------------------------------- --
--                                 Constructor                                --
-- -------------------------------------------------------------------------- --

---@param activationOptions HitDirection_ActivationOptions
---@param widgetOptions HitDirection_WidgetOptions
---@param options HitDirection_Options
---@param textOptions HitDirection_TextOptions
---@return HitDirection
function HitDirection.new(
	activationOptions,
	widgetOptions,
	options,
	textOptions
)
	-- Wait a milisecond to let other mod load first
	Wait(0)

	-- Check required mod is installed or not

	HitDirection._isSimpleFirstPersonInstalled = false
	if HitDirection._CheckSimpleFirstPersonInstalled() then
		HitDirection._isSimpleFirstPersonInstalled = true
		print('"Simple First Person" mod installed.')
	end
	HitDirection._isSimpleCustomThirdPersonInstalled = false
	if HitDirection._CheckSimpleCustomThirdPersonInstalled() then
		HitDirection._isSimpleCustomThirdPersonInstalled = true
		print('"Simple Custom Third Person" mod installed.')
	end

	if
		not HitDirection._isSimpleFirstPersonInstalled
		and not HitDirection._isSimpleCustomThirdPersonInstalled
	then
		error(
			'Missing required mod: "Simple First Person" or "Simple Custom Third'
				.. ' Person".'
		)
	end

	local instance = setmetatable({}, HitDirection)

	-- Instance variables initialization

	instance._enableOnFirstPerson = activationOptions.enableOnFirstPerson
	instance._enableOnThirdPerson = activationOptions.enableOnThirdPerson
	if
		instance._enableOnFirstPerson
		and not HitDirection._isSimpleFirstPersonInstalled
	then
		PrintWarning(
			'`bEnableOnFirstPerson` is set to `true` while "Simple First Person"'
				.. " is not installed."
		)
	end
	if
		instance._enableOnFirstPerson
		and not HitDirection._isSimpleFirstPersonInstalled
	then
		PrintWarning(
			'`bEnableOnThirdPerson` is set to `true` while "Simple Custom Third'
				.. ' Person Camera" is not installed.'
		)
	end

	instance.yaw = 0

	instance.widgets = {}

	instance.centerOffsetPos2d = options.centerOffset
	instance.radius2d = options.radius
	instance.radius2d[1] = UTIL.PixelToNormalized(instance.radius2d[1], "width")
	instance.radius2d[2] = UTIL.PixelToNormalized(instance.radius2d[2], "height")
	instance.timeout = options.timeout

	-- Widget texture

	instance.textureInstance = Texture.create(widgetOptions.imgPath)
	instance.textureInstance:SetAlignment("CENTER", "MIDDLE")
	if widgetOptions.usePixelUnit then
		instance.textureInstance:SetSize(
			PixelToNormalized(widgetOptions.heightInPixel, "height")
				* instance.textureInstance:GetDisplayAspectRatio(),
			PixelToNormalized(widgetOptions.heightInPixel, "height")
		)
	else
		instance.textureInstance:SetSize(
			widgetOptions.heightNormalized
				* instance.textureInstance:GetDisplayAspectRatio(),
			widgetOptions.heightNormalized
		)
	end

	-- Text

	instance.showText = textOptions.show

	instance.textInstance = Text.new("", {
		align = { "CENTER", "CENTER" },
		bold = textOptions.bold,
		color = {
			textOptions.color[1],
			textOptions.color[2],
			textOptions.color[3],
			textOptions.color[4],
		},
		font = textOptions.font or "Segoe UI",
		italic = textOptions.italic or false,
		scale = textOptions.scale or 1.25,
	})

	instance.textInstance:SetOutline(
		textOptions.enableOutline,
		unpack(textOptions.outline)
	)
	instance.textInstance:SetShadow(
		textOptions.enableShadow,
		unpack(textOptions.shadow)
	)

	return instance
end

-- -------------------------------------------------------------------------- --
--                                   Methods                                  --
-- -------------------------------------------------------------------------- --

-- ----------------------------- Private static ----------------------------- --

---@return boolean
function HitDirection._CheckSimpleFirstPersonInstalled()
	if type(_G.SIMPLE_FIRST_PERSON) == "table" then
		return true
	end
	return false
end

---@return boolean
function HitDirection._CheckSimpleCustomThirdPersonInstalled()
	if type(_G.SIMPLE_CUSTOM_THIRD_PERSON) == "table" then
		return true
	end
	return false
end

-- --------------------------------- Public --------------------------------- --

---@param self HitDirection
---@return boolean
local function IsFirstPersonEnabled(self)
	---@diagnostic disable-next-line: invisible
	return self._isSimpleFirstPersonInstalled
		and self:IsEnabledOnPOV("fp")
		and _G.SIMPLE_FIRST_PERSON.GetSingleton():IsEnabled()
end

---@param self HitDirection
---@return boolean
local function IsThirdPersonEnabled(self)
	---@diagnostic disable-next-line: invisible
	return self._isSimpleCustomThirdPersonInstalled
		and self:IsEnabledOnPOV("tp")
		and _G.SIMPLE_CUSTOM_THIRD_PERSON.GetSingleton():IsEnabled()
end

---@return number
function HitDirection:GetYaw()
	if IsFirstPersonEnabled(self) then
		self.yaw = _G.SIMPLE_FIRST_PERSON.GetSingleton():GetYaw()
	elseif IsThirdPersonEnabled(self) then
		self.yaw = _G.SIMPLE_CUSTOM_THIRD_PERSON.GetSingleton():GetYaw()
	end

	return self.yaw
end

-- Weapon hash table, used for damage color when being hit.
local PROJECTILE = {
	-- Red
	HEAVY = {
		[301] = true, -- Fire cracker
		[305] = true, -- Spud gun
		[307] = true, -- Rocket launcher
		[308] = true, -- Rocket launcher ammo
		[316] = true, -- Spud gun ammo
		[396] = true, -- Super spud gun
		[400] = true, -- Football (bomb)
	},

	-- Orange
	MEDIUM = {
		[302] = true, -- Baseball
		[303] = true, -- Slingshot
		[304] = true, -- Slingshot ammo
		[306] = true, -- Super slingshot
		[311] = true, -- Brick
		[313] = true, -- Snowball
		[338] = true, -- Dish
		[353] = true, -- Plant pot
	},

	-- Yellow
	LIGHT = {
		-- [309] = true, -- Stink bomb
		[310] = true, -- Apple
		[312] = true, -- Egg
		[330] = true, -- Big snowball
		[331] = true, -- Football
		[358] = true, -- Banana
	},
}
local playerPos2d = { 0, 0 }
local pedPos2d = { 0, 0 }
local direction = 0
local angleDiff = 0
local widgetData = {
	progress = 0,
	position2d = { 0, 0 },
	color4d = { 0, 0, 0, 0 },
}
local centerOffsetPos2d = { 0, 0 }
local radius2d = { 0, 0 }
local function SetColor(tbl, r, g, b)
	tbl[1] = r
	tbl[2] = g
	tbl[3] = b
end
local textColor3d = { 0, 0, 0, 0 }
function HitDirection:ProcessWidgets()
	if IsFirstPersonEnabled(self) or IsThirdPersonEnabled(self) then
		for ped, widget in pairs(self.widgets) do
			if PedIsValid(ped) then
				playerPos2d[1], playerPos2d[2], _ = PlayerGetPosXYZ()
				pedPos2d[1], pedPos2d[2], _ = PedGetPosXYZ(ped)
				direction =
					math.atan2(pedPos2d[2] - playerPos2d[2], pedPos2d[1] - playerPos2d[1])
				angleDiff = UTIL.FixRadians(self:GetYaw() - direction)

				-- Set the widget color
				-- Red
				if PROJECTILE.HEAVY[widget.weaponId] then
					SetColor(widgetData.color4d, 255, 0, 0)
				-- Orange
				elseif PROJECTILE.MEDIUM[widget.weaponId] then
					SetColor(widgetData.color4d, 255, 127.5, 0)
				-- Yellow
				elseif PROJECTILE.LIGHT[widget.weaponId] then
					SetColor(widgetData.color4d, 255, 255, 0)
					-- White
				else
					SetColor(widgetData.color4d, 255, 255, 255)
				end

				if GetTimer() < widget.startTime + self.timeout then
					widgetData.progress = (GetTimer() - widget.startTime) / self.timeout

					-- Calculate alpha/opacity
					widgetData.color4d[4] =
						UTIL.LerpOptimized(255, 0, widgetData.progress)
					widgetData.color4d[4] = UTIL.Clamp(widgetData.color4d[4], 0, 255)

					-- Calculate center offset position
					centerOffsetPos2d[1] = 0.5 + self.centerOffsetPos2d[1]
					centerOffsetPos2d[2] = 0.5 + self.centerOffsetPos2d[2]

					-- Calculate orbit distance from center point (direction * radius)
					radius2d[1] = math.sin(angleDiff) * self.radius2d[1]
					radius2d[2] = -math.cos(angleDiff) * self.radius2d[2]

					-- Calculate the widget position
					widgetData.position2d[1] = centerOffsetPos2d[1] + radius2d[1]
					widgetData.position2d[2] = centerOffsetPos2d[2] + radius2d[2]

					-- Draw the background (widget)
					self:_DrawWidget(
						widgetData.position2d,
						widgetData.color4d,
						math.deg(angleDiff)
					)

					-- Draw the text
					if self.showText then
						textColor3d[1], textColor3d[2], textColor3d[3], _ =
							self.textInstance:GetColor()
						textColor3d[4] = widgetData.color4d[4]

						self:_DrawText(
							tostring(UTIL.RoundNumberMax2DigitAfterComma(widget.hitDamage)),
							widgetData.position2d,
							textColor3d
						)
					end

				-- If it's over the timeout
				else
					self.widgets[ped] = nil
				end

			-- If the ped is not exist
			else
				self.widgets[ped] = nil
			end
		end
	end
end

local hitDamage = 0
function HitDirection:CheckForInsertWidgetTrigger()
	hitDamage = UTIL.PedGetDamageValueFromHit(gPlayer)

	for _, ped in { PedFindInAreaXYZ(0, 0, 0, 99999) } do
		if PedIsValid(ped) and ped ~= gPlayer and not PedIsDead(ped) then
			if
				PedIsInCombat(ped)
				and PedGetTargetPed(ped) == gPlayer
				and hitDamage > 0
				and PedGetWhoHitMeLast(gPlayer) == ped
				and PedGetLastHitWeapon(gPlayer) ~= -1
			then
				self:InsertWidget(ped, {
					weaponId = PedGetLastHitWeapon(gPlayer),
					hitDamage = 0 - hitDamage,
					startTime = GetTimer(),
				})
			end
		end
	end
end

-- Drawing methods

---@param pos ArrayOfNumbers2D
---@param color ArrayOfNumbers4D
---@param rotation number in degrees
function HitDirection:_DrawWidget(pos, color, rotation)
	self.textureInstance:SetPosition(unpack(pos))
	self.textureInstance:SetColor(unpack(color))
	self.textureInstance:DrawWithRotation(rotation)
end

---@param text string
---@param pos ArrayOfNumbers2D
---@param color ArrayOfNumbers4D
function HitDirection:_DrawText(text, pos, color)
	self.textInstance:SetText(text)
	self.textInstance:SetPosition(unpack(pos))
	self.textInstance:SetColor(unpack(color))
	self.textInstance:Draw()
end

-- Utility methods

---@param pov "fp"|"tp"
---@return boolean
function HitDirection:IsEnabledOnPOV(pov)
	local key = pov == "fp" and "_enableOnFirstPerson" or "_enableOnThirdPerson"
	return self[key]
end

---@param pov "fp"|"tp"
---@param enable boolean
function HitDirection:SetEnabledOnPOV(pov, enable)
	local key = pov == "fp" and "_enableOnFirstPerson" or "_enableOnThirdPerson"
	self[key] = enable
end

---@param ped integer
---@return boolean
function HitDirection:IsWidgetExistWithPed(ped)
	return self.widgets[ped] ~= nil
end

---@param ped integer
---@param widget HitDirection_Widget
function HitDirection:InsertWidget(ped, widget)
	self.widgets[ped] = widget
end

for _, filename in ipairs({
	"utils",
	"Config",
	"DSLCommandManager",
	"HitDirection",
}) do
	LoadScript("src/" .. filename .. ".lua")
end

-- -------------------------------------------------------------------------- --
--                                 Attributes                                 --
-- -------------------------------------------------------------------------- --

---@class HIT_DIRECTION
local privateFields = {
	_INTERNAL = {
		INITIALIZED = false,

		-- Stores the installed custom camera mod
		CAMERA_MOD_INSTALLED = {
			-- [variable_name] = <boolean>

			SIMPLE_FIRST_PERSON = false,
			SIMPLE_CUSTOM_THIRD_PERSON = false,
		},

		COMMAND = {
			NAME = "hitdirection",
			HELP_TEXT = [[hitdirection

Usage:
  - hitdirection <toggle> (Enable/disable the mod, where <toggle> must be "enable" or "disable")
  - hitdirection set <pov> <toggle> (Enable/disable HUD display on specified POV, <pov> must be "fp" or "tp")]],
		},

		CONFIG = {
			FILENAME_WITH_EXTENSION = "settings.ini",
			DEFAULT_SETTING = {
				bEnabled = true,
				bEnableOnFirstPerson = true,
				bEnableOnThirdPerson = true,

				sWidgetImgPath = "assets/images/hit_frame2.png",
				fWidgetHeightNormalized = 0.2,

				bUsePixelOnWidgetHeight = false,
				fWidgetHeightInPixel = 256,
				fCenterOffsetX = 0,
				fCenterOffsetY = 0,
				fRadiusX = 300,
				fRadiusY = 300,
				fTimeout = 3000,

				bShowText = true,
				sTextFont = "Segoe UI",
				bTextBold = true,
				bTextItalic = false,
				fTextScale = 1.25,
				fTextColorR = 255,
				fTextColorG = 255,
				fTextColorB = 255,

				bEnableTextOutline = false,
				fTextOutlineR = 0,
				fTextOutlineG = 0,
				fTextOutlineB = 0,
				bEnableTextShadow = false,
				fTextShadowR = 0,
				fTextShadowG = 0,
				fTextShadowB = 0,
			},
		},

		INSTANCE = {
			---@type HitDirection
			HitDirection = nil,

			---@type Config
			Config = nil,
		},
	},
}

-- -------------------------------------------------------------------------- --
--                               Private Methods                              --
-- -------------------------------------------------------------------------- --

function privateFields._RegisterCommand()
	local command = privateFields._INTERNAL.COMMAND
	local instance = privateFields._INTERNAL.INSTANCE

	-- if not DSLCommandManager.IsAlreadyExist(command.NAME) then
	---@param value string
	---@param thingName string
	---@return boolean
	local function checkIfArgSpecified(value, thingName)
		if not value or value == "" then
			PrintError(thingName .. " didn't specified.")
			return false
		end
		return true
	end

	---@param value string
	---@return boolean
	local function isFirstArgValid(value)
		if not checkIfArgSpecified(value, "Action Type") then
			return false
		end

		if
			not ({
				["enable"] = true,
				["disable"] = true,
				["set"] = true,
			})[string.lower(value)]
		then
			PrintError('Allowed Action Type are "enable"|"disable"|"set".')
			return false
		end

		return true
	end

	---@param value string
	---@return boolean
	local function isSecondArgValid(value)
		if not checkIfArgSpecified(value, "Setting Key") then
			return false
		end

		if not ({ ["fp"] = true, ["tp"] = true })[string.lower(value)] then
			PrintError('Available Setting Key are "fp"|"tp".')
			return false
		end

		return true
	end

	---@param value string
	---@return boolean
	local function isThirdArgValid(value)
		if not checkIfArgSpecified(value, "Setting Value") then
			return false
		end

		if not ({ ["enable"] = true, ["disable"] = true })[string.lower(value)] then
			PrintError('Setting Value must be "enable" or "disable".')
			return false
		end

		return true
	end

	if DSLCommandManager.IsAlreadyExist(command.NAME) then
		DSLCommandManager.Unregister(command.NAME)
	end

	DSLCommandManager.Register(command.NAME, function(...)
		local actionType = arg[1]
		local pov = arg[2]
		local toggle = arg[3]

		if not isFirstArgValid(actionType) then
			return
		end

		actionType = string.lower(arg[1])

		if actionType == "enable" or actionType == "disable" then
			HIT_DIRECTION.SetEnabled(actionType == "enable")
			print("Hit Direction: Mod " .. actionType .. "d.")

		-- actionType == "set"
		else
			-- Grouping matter, really.. (I just know)

			-- This will call both function to make sure the result of `and`
			-- if not isSecondArgValid(pov) and not isThirdArgValid(toggle) then

			-- But this doesn't
			if not (isSecondArgValid(pov) and isThirdArgValid(toggle)) then
				return
			end

			instance.HitDirection:SetEnabledOnPOV(pov, toggle == "enable")
			print(
				string.format(
					"Hit Direction: HUD display %sd on %s POV.",
					toggle,
					pov == "fp" and "First Person" or "Custom Third Person"
				)
			)
		end
	end, {
		rawArgument = false,
		helpText = command.HELP_TEXT,
	})
	-- end
end

---@return boolean isFPInstalled, boolean isCTPInstalled
function privateFields.CheckInstalledCameraMod()
	---@type [boolean, boolean] { fp, tp }
	local camMods = {}

	-- Check the installed camera mod
	for index, varName in pairs({
		"SIMPLE_FIRST_PERSON",
		"SIMPLE_CUSTOM_THIRD_PERSON",
	}) do
		local var = _G[varName]

		if
			type(var) == "table"
			and type(var.GetSingleton) == "function"
			and type(var.GetSingleton()) == "table"
		then
			camMods[index] = true
		end
	end

	return unpack(camMods)
end

-- -------------------------------------------------------------------------- --

-- Hide all the above key/attribute from `pairs()`.

-- Using `_G` notation to create a global variable that can be accessed across
-- different scripts.

privateFields.__index = privateFields

---@class HIT_DIRECTION
_G.HIT_DIRECTION = setmetatable({
	VERSION = "1.0.0",

	DATA = {
		-- The core mod state. This can be toggled only via console.
		IS_ENABLED = true,
	},
}, privateFields)

-- -------------------------------------------------------------------------- --
--                            Public Static Methods                           --
-- -------------------------------------------------------------------------- --

local internal = HIT_DIRECTION._INTERNAL
local instance = internal.INSTANCE

function HIT_DIRECTION.GetSingleton()
	if not instance.HitDirection then
		local conf = instance.Config

		---@type HitDirection_ActivationOptions
		local activationOptions = {
			enableOnFirstPerson = conf:GetSettingValue("bEnableOnFirstPerson") --[[@as boolean]],
			enableOnThirdPerson = conf:GetSettingValue("bEnableOnThirdPerson") --[[@as boolean]],
		}

		---@type HitDirection_WidgetOptions
		local widgetOptions = {
			imgPath = conf:GetSettingValue("sWidgetImgPath") --[[@as string]],
			heightNormalized = conf:GetSettingValue("fWidgetHeightNormalized") --[[@as number]],
			usePixelUnit = conf:GetSettingValue("bUsePixelOnWidgetHeight") --[[@as boolean]],
			heightInPixel = conf:GetSettingValue("fWidgetHeightInPixel") --[[@as number]],
		}

		---@type HitDirection_Options
		local options = {
			centerOffset = {
				conf:GetSettingValue("fCenterOffsetX") --[[@as number]],
				conf:GetSettingValue("fCenterOffsetY") --[[@as number]],
			},
			radius = {
				conf:GetSettingValue("fRadiusX") --[[@as number]],
				conf:GetSettingValue("fRadiusY") --[[@as number]],
			},
			timeout = conf:GetSettingValue("fTimeout") --[[@as number]],
		}

		---@type HitDirection_TextOptions
		local textOptions = {
			show = conf:GetSettingValue("bShowText") --[[@as boolean]],
			font = conf:GetSettingValue("sTextFont") --[[@as string]],
			bold = conf:GetSettingValue("bTextBold") --[[@as boolean]],
			italic = conf:GetSettingValue("bTextItalic") --[[@as boolean]],
			scale = conf:GetSettingValue("fTextScale") --[[@as number]],
			color = {
				conf:GetSettingValue("fTextColorR") --[[@as number]],
				conf:GetSettingValue("fTextColorG") --[[@as number]],
				conf:GetSettingValue("fTextColorB") --[[@as number]],
			},
			enableOutline = conf:GetSettingValue("bEnableTextOutline") --[[@as boolean]],
			outline = {
				conf:GetSettingValue("fTextOutlineR") --[[@as number]],
				conf:GetSettingValue("fTextOutlineG") --[[@as number]],
				conf:GetSettingValue("fTextOutlineB") --[[@as number]],
			},
			enableShadow = conf:GetSettingValue("bEnableTextShadow") --[[@as boolean]],
			shadow = {
				conf:GetSettingValue("fTextShadowR") --[[@as number]],
				conf:GetSettingValue("fTextShadowG") --[[@as number]],
				conf:GetSettingValue("fTextShadowB") --[[@as number]],
			},
		}

		instance.HitDirection =
			HitDirection.new(activationOptions, widgetOptions, options, textOptions)
	end

	return instance.HitDirection
end

function HIT_DIRECTION.Init()
	if not internal.INITIALIZED then
		local camMods = internal.CAMERA_MOD_INSTALLED
		camMods.SIMPLE_FIRST_PERSON, camMods.SIMPLE_CUSTOM_THIRD_PERSON =
			HIT_DIRECTION.CheckInstalledCameraMod()

		instance.Config = Config.new(
			"src/" .. internal.CONFIG.FILENAME_WITH_EXTENSION,
			internal.CONFIG.DEFAULT_SETTING
		)

		instance.HitDirection = HIT_DIRECTION.GetSingleton()

		HIT_DIRECTION._RegisterCommand()

		HIT_DIRECTION.DATA.IS_ENABLED = instance.Config:GetSettingValue("bEnabled") --[[@as boolean]]

		internal.INITIALIZED = true

		-- Delete

		HitDirection = nil --[[@diagnostic disable-line]]

		Config = nil --[[@diagnostic disable-line]]

		Text = nil --[[@diagnostic disable-line]]
		Texture = nil --[[@diagnostic disable-line]]

		collectgarbage()
	end
end

---@return string
function HIT_DIRECTION.GetVersion()
	return HIT_DIRECTION.VERSION
end

---@return boolean
function HIT_DIRECTION.IsEnabled()
	return HIT_DIRECTION.DATA.IS_ENABLED
end

---@param enable boolean
function HIT_DIRECTION.SetEnabled(enable)
	HIT_DIRECTION.DATA.IS_ENABLED = enable
end

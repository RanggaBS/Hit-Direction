--[[
	A modification script for Bully SE game

	Mod name: Hit Direction
	Author: RBS ID

	Requirements:
		- Derpy's Script Loader v7 or greater
]]

-- Header

RequireLoaderVersion(7)

-- -------------------------------------------------------------------------- --
--                                 Entry Point                                --
-- -------------------------------------------------------------------------- --

function main()
	while not SystemIsReady() do
		Wait(0)
	end

	LoadScript("src/setup.lua")

	local MOD = HIT_DIRECTION

	MOD.Init()

	local hitDir = MOD.GetSingleton()

	while true do
		Wait(0)

		if
			MOD.IsEnabled()
			and (hitDir:IsEnabledOnPOV("fp") or hitDir:IsEnabledOnPOV("tp"))
		then
			hitDir:CheckForInsertWidgetTrigger()
			hitDir:ProcessWidgets()
		end
	end
end

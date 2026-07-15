EnableBackground = playersettings.BGDisplay
if EnableBackground == nil then
	EnableBackground = true
end

BackgroundColor = playersettings.BGColor or Black
BackgroundAlpha = playersettings.BGAlpha or 255

BackgroundPaddingX = playersettings.BGPaddingX or 0
BackgroundPaddingY = playersettings.BGPaddingY or 0
local BackgroundOffsetX = playersettings.BGOffsetX or 0
local BackgroundOffsetY = playersettings.BGOffsetY or 0
local BackgroundNameRoot = "AAEV_Background_"

function CreateBackground(Visible, ChartType)
	local BackgroundStartX = 0
	local BackgroundStartY = 0
	local BackgroundWidth = 0
	local BackgroundHeight = 0
	local BackgroundName = GetBackgroundName(ChartType)

	if ChartType == TYPE_PLAYER then
		BackgroundStartX = ChartStartX
		BackgroundStartY = ChartStartY
		BackgroundWidth = ChartWidth
		BackgroundHeight = ChartHeight
	elseif ChartType == TYPE_PET then
		BackgroundStartX = PetChartStartX
		BackgroundStartY = PetChartStartY
		BackgroundWidth = PetChartWidth
		BackgroundHeight = PetChartHeight
	else
		print("Invalid ChartType in CreateBackground.")
		return
	end

	if EnableBackground then
		windower.prim.create(BackgroundName)
		windower.prim.set_position(BackgroundName, BackgroundStartX - BackgroundPaddingX + BackgroundOffsetX, BackgroundStartY + BackgroundPaddingY - BackgroundOffsetY)
		windower.prim.set_size(BackgroundName, BackgroundWidth + (2*BackgroundPaddingX) , -1 * (BackgroundHeight + (2*BackgroundPaddingY)))
		windower.prim.set_color(BackgroundName, BackgroundAlpha, BackgroundColor[1], BackgroundColor[2], BackgroundColor[3])
		windower.prim.set_visibility(BackgroundName, Visible)
	end
end

function CreatePlayerBackground(Visible)
	CreateBackground(Visible, TYPE_PLAYER)
end

function CreatePetBackground(Visible)
	CreateBackground(Visible, TYPE_PET)
end

function DisplayBackground(Visible, ChartType)
	if EnableBackground then
		local BackgroundName = GetBackgroundName(ChartType)
		windower.prim.set_visibility(BackgroundName, Visible)
	end
end

function DisplayPlayerBackground(Visible)
	DisplayBackground(Visible, TYPE_PLAYER)
end

function DisplayPetBackground(Visible)
	DisplayBackground(Visible, TYPE_PET)
end

function DestroyPetBackground()
	windower.prim.delete(GetBackgroundName(TYPE_PET))
end

function GetBackgroundName(ChartType)
	return BackgroundNameRoot .. "_" .. ChartType
end
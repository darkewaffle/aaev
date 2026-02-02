local EnableBackground = playersettings.BGDisplay
if EnableBackground == nil then
	EnableBackground = true
end

local BackgroundColor = playersettings.BGColor or Black
local BackgroundPaddingX = playersettings.BGPaddingX or 0
local BackgroundPaddingY = playersettings.BGPaddingY or 0
local BackgroundAlpha = playersettings.BGAlpha or 255
local BackgroundName = "AAEV_Background"

function CreateBackground(Visible)
	if EnableBackground then
		windower.prim.create(BackgroundName)
		windower.prim.set_position(BackgroundName, ChartStartX - BackgroundPaddingX, ChartStartY + BackgroundPaddingY)
		windower.prim.set_size(BackgroundName, ChartWidth + (2*BackgroundPaddingX) , -1 * (ChartHeight + (2*BackgroundPaddingY)))
		windower.prim.set_color(BackgroundName, BackgroundAlpha, BackgroundColor[1], BackgroundColor[2], BackgroundColor[3])
		windower.prim.set_visibility(BackgroundName, Visible)
	end
end

function DisplayBackground(Visible)
	if EnableBackground then
		windower.prim.set_visibility(BackgroundName, Visible)
	end
end
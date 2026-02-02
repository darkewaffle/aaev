local EnableBackground = playersettings.BGDisplay
if EnableBackground == nil then
	EnableBackground = true
end

local BackgroundColor = playersettings.BGColor or Black
local BackgroundPadding = playersettings.BGPadding or 0
local BackgroundAlpha = playersettings.BGAlpha or 255
local BackgroundName = "AAEV_Background"

function CreateBackground(Visible)
	if EnableBackground then
		windower.prim.create(BackgroundName)
		windower.prim.set_position(BackgroundName, ChartStartX - BackgroundPadding, ChartStartY + BackgroundPadding)
		windower.prim.set_size(BackgroundName, ChartWidth + (2*BackgroundPadding) , -1 * (ChartHeight + (2*BackgroundPadding)))
		windower.prim.set_color(BackgroundName, BackgroundAlpha, BackgroundColor[1], BackgroundColor[2], BackgroundColor[3])
		windower.prim.set_visibility(BackgroundName, Visible)
	end
end

function DisplayBackground(Visible)
	if EnableBackground then
		windower.prim.set_visibility(BackgroundName, Visible)
	end
end
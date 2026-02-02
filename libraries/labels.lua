local EnableMaxLabel = playersettings.DisplayMax
if EnableMaxLabel == nil then
	EnableMaxLabel = true
end

local EnableHitRate = playersettings.DisplayHitRate
if EnableHitRate == nil then
	EnableHitRate = true
end

local MaxLabelPrefix = playersettings.MaxLabelPrefix or "Max: "
local HitRateLabelPrefix = playersettings.HitRateLabelPrefix or "Hit: "


local LabelOffsetUp = playersettings.LabelOffsetUp or 25
local LabelOffsetDown = playersettings.LabelOffsetDown or 5
local LabelOffsetRight = playersettings.LabelOffsetRight or 0


function CreateLabels(Visible)
	local LabelSettings = GetLabelSettings()

	if EnableMaxLabel then
		LabelSettings.pos.x = ChartStartX + LabelOffsetRight
		LabelSettings.pos.y = ChartStartY - ChartHeight - LabelOffsetUp
		MaxLabel = texts.new("Max", LabelSettings)
		MaxLabel:visible(Visible)
	end

	if EnableHitRate then
		LabelSettings.pos.x = ChartStartX + LabelOffsetRight
		LabelSettings.pos.y = ChartStartY + LabelOffsetDown
		HitRateLabel = texts.new("HitRate", LabelSettings)
		HitRateLabel:visible(Visible) 
	end
end

function UpdateLabels(TargetID)
	if EnableMaxLabel then
		local MaxDamage = AttackLog[TargetID]["max"]
		local MaxDamageString = "0"

		if MaxDamage < 100 then
			MaxDamageString = tostring(MaxDamage)
		elseif MaxDamage >= 100 and MaxDamage < 1000 then
			MaxDamageString = tostring(math.floor(MaxDamage / 10) * 10)
		elseif MaxDamage >= 1000 and MaxDamage < 10000 then
			MaxDamageString = tostring(math.floor(MaxDamage / 100) * 100)
		elseif MaxDamage >= 10000 then
			MaxDamageString = tostring (math.floor(MaxDamage / 1000) * 1000)
		end
 
		MaxLabel:visible(true)
		MaxLabel:text(MaxLabelPrefix .. MaxDamageString)
	end

	if EnableHitRate then
		local HitRate = (AttackLog[TargetID]["count"] - AttackLog[TargetID][ATTACK_MISS]) / AttackLog[TargetID]["count"] * 100
		local HitRateString = string.format("%.1f", HitRate)
		HitRateLabel:visible(true)
		HitRateLabel:text(HitRateLabelPrefix .. HitRateString .. "%")
	end
end

function DisplayLabels(Visible)
	if EnableMaxLabel then
		MaxLabel:visible(Visible)
	end

	if EnableHitRate then
		HitRateLabel:visible(Visible)
	end
end

function GetLabelSettings()

	local LabelSettings = {}
	LabelSettings.pos = {}
	LabelSettings.bg = {}
	LabelSettings.flags = {}
	LabelSettings.text = {}
	LabelSettings.text.fonts = {}
	LabelSettings.text.stroke = {}

	LabelSettings.pos.x = 0
	LabelSettings.pos.y = 0

	LabelSettings.bg.alpha   = 0
	LabelSettings.bg.red     = 0
	LabelSettings.bg.green   = 0
	LabelSettings.bg.blue    = 0
	LabelSettings.bg.visible = false

	LabelSettings.flags.right     = false
	LabelSettings.flags.bottom    = false
	LabelSettings.flags.bold      = false
	LabelSettings.flags.draggable = false
	LabelSettings.flags.italic    = false

	LabelSettings.padding = 0

	LabelSettings.text.size  = playersettings.LabelSize or 12
	LabelSettings.text.font  = playersettings.LabelFont or 'Consolas'
	LabelSettings.text.alpha = playersettings.LabelAlpha or 255
	LabelSettings.text.red   = playersettings.LabelColor[1] or 255
	LabelSettings.text.green = playersettings.LabelColor[2] or 255
	LabelSettings.text.blue  = playersettings.LabelColor[3] or 255

	LabelSettings.text.stroke.width = playersettings.LabelHighlightThickness or 1
	LabelSettings.text.stroke.alpha = playersettings.LabelHighlightAlpha or 255
	LabelSettings.text.stroke.red   = playersettings.LabelHighlightColor[1] or 0
	LabelSettings.text.stroke.green = playersettings.LabelHighlightColor[2] or 0
	LabelSettings.text.stroke.blue  = playersettings.LabelHighlightColor[3] or 0

	return LabelSettings
end
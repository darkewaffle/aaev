local DisplayMax = playersettings.DisplayMax
if DisplayMax == nil then
	DisplayMax = true
end

local DisplayHitRate = playersettings.DisplayHitRate
if DisplayHitRate == nil then
	DisplayHitRate = true
end

function CreateLabels(Visible)
	local LabelSettings = GetLabelSettings()

	if DisplayMax then
		LabelSettings.pos.x = ChartStartX
		LabelSettings.pos.y = ChartStartY - ChartHeight - 25
		MaxLabel = texts.new("Max", LabelSettings)
		MaxLabel:visible(Visible)
	end

	if DisplayHitRate then
		LabelSettings.pos.x = ChartStartX
		LabelSettings.pos.y = ChartStartY + 5
		HitRateLabel = texts.new("HitRate", LabelSettings)
		HitRateLabel:visible(Visible) 
	end
end

function UpdateLabels(TargetID)
	if DisplayMax then
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
		MaxLabel:text("Max: " .. MaxDamageString)
	end

	if DisplayHitRate then
		local HitRate = (AttackLog[TargetID]["count"] - AttackLog[TargetID][ATTACK_MISS]) / AttackLog[TargetID]["count"] * 100
		local HitRateString = string.format("%.1f", HitRate)
		HitRateLabel:visible(true)
		HitRateLabel:text("Hit: " .. HitRateString .. "%")
	end
end

function DisplayLabels(Visible)
	if DisplayMax then
		MaxLabel:visible(Visible)
	end

	if DisplayHitRate then
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

	LabelSettings.text.size  = 12
	LabelSettings.text.font  = 'Consolas'
	LabelSettings.text.alpha = 255
	LabelSettings.text.red   = 255
	LabelSettings.text.green = 255
	LabelSettings.text.blue  = 255

	LabelSettings.text.stroke.width = 1
	LabelSettings.text.stroke.alpha = 255
	LabelSettings.text.stroke.red   = 0
	LabelSettings.text.stroke.green = 0
	LabelSettings.text.stroke.blue  = 0

	return LabelSettings
end
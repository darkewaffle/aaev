local EnableMaxLabel = playersettings.DisplayMax
if EnableMaxLabel == nil then
	EnableMaxLabel = true
end

local EnableHitRate = playersettings.DisplayHitRate
if EnableHitRate == nil then
	EnableHitRate = true
end

local EnableWSDisplay = playersettings.DisplayWeaponskills
if EnableWSDisplay == nil then
	EnableWSDisplay = true
end

local ReverseWeaponskills = playersettings.ReverseWeaponskills
if ReverseWeaponskills == nil then
	ReverseWeaponskills = false
end

local MaxLabelPrefix = playersettings.MaxLabelPrefix or "Max: "
local HitRateLabelPrefix = playersettings.HitRateLabelPrefix or "Hit: "


local LabelOffsetUp = playersettings.LabelOffsetUp or 25
local LabelOffsetDown = playersettings.LabelOffsetDown or 5
local LabelOffsetRight = playersettings.LabelOffsetRight or 0

local WeaponskillX = playersettings.WeaponskillX or ChartStartX + ChartWidth + BackgroundPaddingX
local WeaponskillY = playersettings.WeaponskillY or ChartStartY - BackgroundPaddingY

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

	if EnableWSDisplay then
		LabelSettings.pos.x = WeaponskillX
		LabelSettings.pos.y = WeaponskillY - ChartHeight

		if EnableBackground then
			LabelSettings.bg.visible = true
			LabelSettings.bg.alpha = BackgroundAlpha
			LabelSettings.bg.red = BackgroundColor[1]
			LabelSettings.bg.green = BackgroundColor[2]
			LabelSettings.bg.blue = BackgroundColor[3]
		end

		WeaponskillDisplay = texts.new("WS", LabelSettings)
		WeaponskillDisplay:visible(Visible)
	end

end

function UpdateLabels(TargetID)
	if EnableMaxLabel then
		local MaxDamage = AttackLog[TargetID][ATTACK_MAX]
		local MaxDamageString = "0"

		if MaxDamage > 0 and MaxDamage < 100 then
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
		local HitRate = 0
		if AttackLog[TargetID][ATTACK_COUNT] > 0 then
			HitRate = (AttackLog[TargetID][ATTACK_COUNT] - AttackLog[TargetID][ATTACK_MISS]) / AttackLog[TargetID][ATTACK_COUNT] * 100
		end

		local HitRateString = string.format("%.1f", HitRate)
		HitRateLabel:visible(true)
		HitRateLabel:text(HitRateLabelPrefix .. HitRateString .. "%")
	end

	if EnableWSDisplay then
		if #AttackLog[TargetID][WEAPON_SKILL_LOG] > 0 then
		local WSText = ""

		local IterateStart = 1
		local IterateEnd = #AttackLog[TargetID][WEAPON_SKILL_LOG]
		local IterateStep = 1

			if ReverseWeaponskills then
			IterateStart = #AttackLog[TargetID][WEAPON_SKILL_LOG]
			IterateEnd = 1
			IterateStep = -1
		end

		for i=IterateStart, IterateEnd, IterateStep do
			local WSInfo = AttackLog[TargetID][WEAPON_SKILL_LOG][i]
			local WSLine = CleanWSName(WSInfo[WS_NAME]) .. " " .. FormatWSDamage(WSInfo[WS_DAMAGE])

			if WSInfo[WS_RESULT] == ATTACK_HEAL then
				WSLine = ColorWrapForTexts(WSLine, ColorHeal[1], ColorHeal[2], ColorHeal[3])
			end
			WSText = WSText .. WSLine

			if WSInfo[SC_NAME] then
				WSText = WSText .. " + "
				local SCLine = string.sub(WSInfo[SC_NAME], 1, 5) .. " " .. FormatWSDamage(WSInfo[SC_DAMAGE])
				
				if WSInfo[SC_RESULT] == ATTACK_HEAL then
					SCLine = ColorWrapForTexts(SCLine, ColorHeal[1], ColorHeal[2], ColorHeal[3])
				end
				WSText = WSText .. SCLine
			end

			if i ~= IterateEnd then
				WSText = WSText .. " \n"
			end
		end

		WeaponskillDisplay:visible(true)
		WeaponskillDisplay:text(WSText)
	else
		WeaponskillDisplay:visible(false)
		end
	end
end

function DisplayLabels(Visible)
	if EnableMaxLabel then
		MaxLabel:visible(Visible)
	end

	if EnableHitRate then
		HitRateLabel:visible(Visible)
	end

	if EnableWSDisplay then
		WeaponskillDisplay:visible(Visible)
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

function CleanWSName(InputString)
	InputString = string.gsub(InputString, "Blade: ", "")
	InputString = string.gsub(InputString, "Tachi: ", "")
	InputString = string.gsub(InputString, "'", "")
	InputString = string.gsub(InputString, " ", "")
	InputString = string.sub(InputString, 1, 5)
	InputString = SetStringWidth(InputString, 5, " ", true)
	return " " .. InputString
end

function FormatWSDamage(InputDamage)
	InputDamage = SetStringWidth(InputDamage, 5, " ", true)
	return InputDamage
end
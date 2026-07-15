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

function CreateLabels(Visible, ChartType)
	local LabelX = 0
	local LabelY = 0
	local BackgroundWidth = 0
	local WeaponskillX = 0
	local WeaponskillY = 0

	if ChartType == TYPE_PLAYER then
		LabelX = ChartStartX
		LabelY = ChartStartY
		BackgroundWidth = ChartWidth
		BackgroundHeight = ChartHeight
		WeaponskillX = playersettings.WeaponskillX or ChartStartX + ChartWidth + BackgroundPaddingX
		WeaponskillY = playersettings.WeaponskillY or ChartStartY - BackgroundPaddingY

	elseif ChartType == TYPE_PET then
		LabelX = PetChartStartX
		LabelY = PetChartStartY
		BackgroundWidth = PetChartWidth
		BackgroundHeight = PetChartHeight
		WeaponskillX = playersettings.PetWeaponskillX or PetChartStartX + PetChartWidth + BackgroundPaddingX
		WeaponskillY = playersettings.PetWeaponskillY or PetChartStartY - BackgroundPaddingY

	else
		print("Invalid ChartType in CreateLabels.")
		return
	end

	local LabelSettings = GetLabelSettings()

	if EnableMaxLabel then
		LabelSettings.pos.x = LabelX + LabelOffsetRight
		LabelSettings.pos.y = LabelY - BackgroundHeight - LabelOffsetUp

		if ChartType == TYPE_PLAYER then
			PlayerMaxLabel = WINDOWER_TEXTS.new("PlayerMax", LabelSettings)
			PlayerMaxLabel:visible(Visible)
		elseif ChartType == TYPE_PET then
			PetMaxLabel = WINDOWER_TEXTS.new("PetMax", LabelSettings)
			PetMaxLabel:visible(Visible)
		end
	end

	if EnableHitRate then
		LabelSettings.pos.x = LabelX + LabelOffsetRight
		LabelSettings.pos.y = LabelY + LabelOffsetDown

		if ChartType == TYPE_PLAYER then
			PlayerHitLabel = WINDOWER_TEXTS.new("PlayerHit", LabelSettings)
			PlayerHitLabel:visible(Visible)
		elseif ChartType == TYPE_PET then
			PetHitLabel = WINDOWER_TEXTS.new("PetHit", LabelSettings)
			PetHitLabel:visible(Visible)
		end
	end

	if EnableWSDisplay then
		LabelSettings.pos.x = WeaponskillX
		LabelSettings.pos.y = WeaponskillY - BackgroundHeight

		if EnableBackground then
			LabelSettings.bg.visible = true
			LabelSettings.bg.alpha = BackgroundAlpha
			LabelSettings.bg.red = BackgroundColor[1]
			LabelSettings.bg.green = BackgroundColor[2]
			LabelSettings.bg.blue = BackgroundColor[3]
		end

		if ChartType == TYPE_PLAYER then
			PlayerWSDisplay = WINDOWER_TEXTS.new("PlayerWS", LabelSettings)
			PlayerWSDisplay:visible(Visible)
		elseif ChartType == TYPE_PET then
			PetWSDisplay = WINDOWER_TEXTS.new("PetWS", LabelSettings)
			PetWSDisplay:visible(Visible)
		end
	end
end

function CreatePetLabels(Visible)
	CreateLabels(Visible, TYPE_PET)
end

function CreatePlayerLabels(Visible)
	CreateLabels(Visible, TYPE_PLAYER)
end

function UpdateLabels(TargetID, ChartType)
	UpdateMaxLabel(TargetID, ChartType)
	UpdateHitLabel(TargetID, ChartType)
	UpdateWSLabel(TargetID, ChartType)
end

function UpdatePetLabels(TargetID)
	UpdateLabels(TargetID, TYPE_PET)
end

function UpdatePlayerLabels(TargetID)
	UpdateLabels(TargetID, TYPE_PLAYER)
end

function UpdateMaxLabel(TargetID, ChartType)
	if EnableMaxLabel then

		local MaxLabel = GetLabelMax(ChartType)
		local AttackLog = GetAttackLogForType(ChartType)

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
end

function UpdateHitLabel(TargetID, ChartType)
	if EnableHitRate then
		local HitLabel = GetLabelHit(ChartType)
		local AttackLog = GetAttackLogForType(ChartType)

		local HitRate = 0
		if AttackLog[TargetID][ATTACK_COUNT] > 0 then
			HitRate = (AttackLog[TargetID][ATTACK_COUNT] - AttackLog[TargetID][ATTACK_MISS]) / AttackLog[TargetID][ATTACK_COUNT] * 100
		end

		local HitRateString = string.format("%.1f", HitRate)
		HitLabel:visible(true)
		HitLabel:text(HitRateLabelPrefix .. HitRateString .. "%")
	end
end

function UpdateWSLabel(TargetID, ChartType)
	if EnableWSDisplay then

		local WSDisplay = GetLabelWS(ChartType)
		local AttackLog = GetAttackLogForType(ChartType)

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
				local WSDamage = FormatWSDamage(WSInfo[WS_DAMAGE])

				if WSInfo[WS_RESULT] == ATTACK_MISS then
					WSDamage = " MISS"
				end

				local WSLine = " " .. CleanWSName(WSInfo[WS_NAME]) .. " " .. WSDamage

				if WSInfo[WS_RESULT] == ATTACK_HEAL then
					WSLine = ColorWrapForTexts(WSLine, ColorHeal[1], ColorHeal[2], ColorHeal[3])
				end

				if WSInfo[SC_NAME] then
					WSLine = WSLine .. " + "
					local SCLine = string.sub(WSInfo[SC_NAME], 1, 5) .. " " .. FormatWSDamage(WSInfo[SC_DAMAGE])
					
					if WSInfo[SC_RESULT] == ATTACK_HEAL then
						SCLine = ColorWrapForTexts(SCLine, ColorHeal[1], ColorHeal[2], ColorHeal[3])
					end
					WSLine = WSLine .. SCLine
				end
				
				WSText = WSText .. WSLine .. " "

				if i ~= IterateEnd then
					WSText = WSText .. "\n"
				end
			end

			WSDisplay:visible(true)
			WSDisplay:text(WSText)
		else
			WSDisplay:visible(false)
		end
	end
end

function DisplayLabels(Visible, ChartType)
	local MaxLabel = GetLabelMax(ChartType)
	local HitLabel = GetLabelHit(ChartType)
	local WSDisplay = GetLabelWS(ChartType)

	if EnableMaxLabel and MaxLabel then
		MaxLabel:visible(Visible)
	end

	if EnableHitRate and HitLabel then
		HitLabel:visible(Visible)
	end

	if EnableWSDisplay and WSDisplay then
		WSDisplay:visible(Visible)
	end
end

function DisplayPetLabels(Visible)
	DisplayLabels(Visible, TYPE_PET)
end

function DisplayPlayerLabels(Visible)
	DisplayLabels(Visible, TYPE_PLAYER)
end

function DestroyPetLabels()
	local MaxLabel = GetLabelMax(TYPE_PET)
	local HitLabel = GetLabelHit(TYPE_PET)
	local WSDisplay = GetLabelWS(TYPE_PET)

	if MaxLabel then
		MaxLabel:destroy()
	end

	if HitLabel then
		HitLabel:destroy()
	end

	if WSDisplay then
		WSDisplay:destroy()
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


function GetLabelMax(ChartType)
	if ChartType == TYPE_PLAYER then
		return PlayerMaxLabel
	elseif ChartType == TYPE_PET then
		return PetMaxLabel
	end
end

function GetLabelHit(ChartType)
	if ChartType == TYPE_PLAYER then
		return PlayerHitLabel
	elseif ChartType == TYPE_PET then
		return PetHitLabel
	end
end

function GetLabelWS(ChartType)
	if ChartType == TYPE_PLAYER then
		return PlayerWSDisplay
	elseif ChartType == TYPE_PET then
		return PetWSDisplay
	end
end

function CleanWSName(InputString)
	InputString = string.gsub(InputString, "Blade: ", "")
	InputString = string.gsub(InputString, "Tachi: ", "")
	InputString = string.gsub(InputString, "'", "")
	InputString = string.gsub(InputString, " ", "")
	InputString = string.sub(InputString, 1, 5)
	InputString = string.format("%5s", InputString)
	return InputString
end

function FormatWSDamage(InputDamage)
	InputDamage = string.format("%5s", InputDamage)
	return InputDamage
end
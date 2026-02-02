local BarsAlpha = playersettings.BarsAlpha or 255
local BarWidth = ChartWidth / ChartBars

local ColorHit = playersettings.ColorHit or RedPale
local ColorMiss = playersettings.ColorMiss or White
local ColorHitZero = playersettings.ColorHitZero or Grey2
local ColorCrit = playersettings.ColorCrit or Red

local BarNameRoot = "AAEV_Bar"

function CreateBars(Visible)
	for i = 1, ChartBars do
		local BarName = BarNameRoot .. i
		windower.prim.create(BarName)
		windower.prim.set_position(BarName, ChartStartX + (BarWidth * (i-1)), ChartStartY)
		windower.prim.set_size(BarName, BarWidth, ChartHeight * -1)
		windower.prim.set_color(BarName, BarsAlpha, 5*i, 5*i, 5*i)
		windower.prim.set_visibility(BarName, Visible)
	end
end

function UpdateBars(TargetID)
	local MaxDamage = AttackLog[TargetID]["max"]

	for i = 1, ChartBars do
		local BarName = BarNameRoot .. i

		if AttackLog[TargetID][i] then
			local AttackDamage = AttackLog[TargetID][i]["damage"]
			local AttackResult = AttackLog[TargetID][i]["result"]
			local DamageHeight = 0
			
			if MaxDamage > 0 then
				DamageHeight = math.floor(AttackDamage / MaxDamage * ChartHeight) * -1
			end

			windower.prim.set_visibility(BarName, true)
			SetBarStyle(BarName, AttackResult, DamageHeight)

		else
			windower.prim.set_visibility(BarName, false)
		end
	end
end

function DisplayBars(Visible)
	for i = 1, ChartBars do
		local BarName = BarNameRoot .. i
		windower.prim.set_visibility(BarName, Visible)
	end
end

function SetBarColor(BarName, BarColor)
	windower.prim.set_color(BarName, BarsAlpha, BarColor[1], BarColor[2], BarColor[3])
end

function SetBarStyle(BarName, AttackResult, DamageHeight)
	if DisplayMode == "full" then

		if AttackResult == ATTACK_HIT then
			windower.prim.set_size(BarName, BarWidth, DamageHeight)
			SetBarColor(BarName, ColorHit)

		elseif AttackResult == ATTACK_CRIT then
			windower.prim.set_size(BarName, BarWidth, DamageHeight)
			SetBarColor(BarName, ColorCrit)

		elseif AttackResult == ATTACK_HIT_ZERO then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorHitZero)

		elseif AttackResult == ATTACK_MISS then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorMiss)
		end

	elseif DisplayMode == "simple" then

		if AttackResult == ATTACK_HIT or AttackResult == ATTACK_CRIT then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorHit)

		elseif AttackResult == ATTACK_HIT_ZERO then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorHitZero)

		elseif AttackResult == ATTACK_MISS then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorMiss)
		end

	end
end
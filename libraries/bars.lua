local BarsAlpha = playersettings.BarsAlpha or 255
local BarWidth = ChartWidth / ChartBars

local ColorHit = playersettings.ColorHit or Blue
local ColorCrit = playersettings.ColorCrit or BluePale
local ColorMiss = playersettings.ColorMiss or White
local ColorBlock = playersettings.ColorBlock or Grey3
local ColorHitZero = playersettings.ColorHitZero or Grey2
local ColorAE = playersettings.ColorAdditionalEffect or Grey1

local BarNameRoot = "AAEV_Bar"
local BarNameAE = BarNameRoot .. "_AE"

function CreateBars(Visible)
	for i = 1, ChartBars do
		local BarName = BarNameRoot .. i
		windower.prim.create(BarName)
		windower.prim.set_position(BarName, ChartStartX + (BarWidth * (i-1)), ChartStartY)
		windower.prim.set_size(BarName, BarWidth, ChartHeight * -1)
		windower.prim.set_color(BarName, BarsAlpha, 5*i, 5*i, 5*i)
		windower.prim.set_visibility(BarName, Visible)

		if AdditionalEffectStackBars then
			BarName = BarNameAE .. i
			windower.prim.create(BarName)
			windower.prim.set_position(BarName, ChartStartX + (BarWidth * (i-1)), ChartStartY)
			windower.prim.set_size(BarName, BarWidth, ChartHeight * -1)
			windower.prim.set_color(BarName, BarsAlpha, 5*i, 5*i, 5*i)
			windower.prim.set_visibility(BarName, false)
		end

	end
end

function UpdateBars(TargetID)
	local MaxDamage = AttackLog[TargetID]["max"]

	for i = 1, ChartBars do
		local BarAttack = BarNameRoot .. i
		local BarAE = BarNameAE .. i

		if AttackLog[TargetID][i] then
			local AttackDamage = AttackLog[TargetID][i]["damage"]
			local AdditionalEffectDamage = AttackLog[TargetID][i]["additionaleffect"]
			local AttackResult = AttackLog[TargetID][i]["result"]
			local DamageHeight = 0
			
			if AdditionalEffectSingleBar then
				AttackDamage = AttackDamage + AdditionalEffectDamage
			end

			if MaxDamage > 0 then
				DamageHeight = math.floor(AttackDamage / MaxDamage * ChartHeight) * -1
				AEHeight = math.floor(AdditionalEffectDamage / MaxDamage * ChartHeight) * -1
			end

			windower.prim.set_visibility(BarAttack, true)
			SetBarStyle(BarAttack, AttackResult, DamageHeight)

			-- If AE damage should be stacked as a second bar and AE damage > 0
			if not AdditionalEffectSingleBar and AdditionalEffectStackBars and AdditionalEffectDamage > 0 then

				-- Set the position. Horizontal does not need changed (same as the created value), vertical position is offset by the damage height calculated for the physical hit
				windower.prim.set_position(BarAE, ChartStartX + (BarWidth * (i-1)), ChartStartY + DamageHeight)
				-- Set size. BarWidth is unchanged, height is determined by Additional Effect Damage / Max Damage.
				windower.prim.set_size(BarAE, BarWidth, AEHeight)

				SetBarColor(BarAE, ColorAE)
				windower.prim.set_visibility(BarAE, true)
			else
				windower.prim.set_visibility(BarAE, false)
			end

		else
			windower.prim.set_visibility(BarAttack, false)
			windower.prim.set_visibility(BarAE, false)
		end
	end
end

function DisplayBars(Visible)
	for i = 1, ChartBars do
		local BarName = BarNameRoot .. i
		windower.prim.set_visibility(BarName, Visible)

		if AdditionalEffectStackBars then
			BarName = BarNameAE .. i
			windower.prim.set_visibility(BarName, Visible)
		end
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

		elseif AttackResult == ATTACK_MISS then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorMiss)

		elseif AttackResult == ATTACK_BLOCK then
			windower.prim.set_size(BarName, BarWidth, DamageHeight)
			SetBarColor(BarName, ColorBlock)

		elseif AttackResult == ATTACK_HIT_ZERO then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorHitZero)
		end

	elseif DisplayMode == "simple" then

		if AttackResult == ATTACK_HIT or AttackResult == ATTACK_CRIT then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorHit)

		elseif AttackResult == ATTACK_MISS then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorMiss)

		elseif AttackResult == ATTACK_BLOCK then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorBlock)

		elseif AttackResult == ATTACK_HIT_ZERO then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorHitZero)
		end

	end
end
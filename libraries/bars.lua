local BarsAlpha = playersettings.BarsAlpha or 255
local BarWidth = ChartWidth / ChartBars

local ColorHit = playersettings.ColorHit or Blue
local ColorCrit = playersettings.ColorCrit or BluePale
local ColorMiss = playersettings.ColorMiss or White
local ColorBlock = playersettings.ColorBlock or Grey3
local ColorHitZero = playersettings.ColorHitZero or Grey2
local ColorHeal = playersettings.ColorHeal or GreenLime
local ColorAE = playersettings.ColorAdditionalEffect or Grey1
local ColorAEHeal = playersettings.ColorAdditionalEffectHeal or GreenLime


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
	local MaxDamage = AttackLog[TargetID][ATTACK_MAX]

	for i = 1, ChartBars do
		local BarAttack = BarNameRoot .. i
		local BarAE = BarNameAE .. i

		if AttackLog[TargetID][i] then
			local AttackResult = AttackLog[TargetID][i][ATTACK_RESULT]
			local AttackDamage = AttackLog[TargetID][i][ATTACK_DAMAGE]

			local AdditionalEffectResult = AttackLog[TargetID][i][AE_RESULT]
			local AdditionalEffectDamage = AttackLog[TargetID][i][AE_DAMAGE]

			local DamageHeight = 0
			
			if AdditionalEffectSingleBar then
				AttackDamage = AttackDamage + AdditionalEffectDamage
			end

			if MaxDamage > 0 then
				DamageHeight = math.floor(AttackDamage / MaxDamage * ChartHeight) * -1
				AEHeight = math.floor(AdditionalEffectDamage / MaxDamage * ChartHeight) * -1

				-- Heals do not affect max damage so if not clamped their damage can outscale the chart
				if AttackResult == ATTACK_HEAL then
					DamageHeight = Clamp(DamageHeight, ChartHeight * -1, 0)
				end

				if AdditionalEffectResult == AE_HEAL then
					AEHeight = Clamp(DamageHeight, ChartHeight * -1, 0)
				end
			end

			windower.prim.set_visibility(BarAttack, true)
			SetBarStyle(BarAttack, AttackResult, DamageHeight)


			-- If AE damage should be stacked as a second bar and AE damage > 0
			if not AdditionalEffectSingleBar and AdditionalEffectStackBars and AdditionalEffectDamage > 0 then

				windower.prim.set_visibility(BarAE, true)
				SetBarStyle(BarAE, AdditionalEffectResult, AEHeight)

				-- Adjust the position. Horizontal does not need changed (same as the created value), vertical position is offset by the damage height calculated for the physical hit
				windower.prim.set_position(BarAE, ChartStartX + (BarWidth * (i-1)), ChartStartY + DamageHeight)

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

function SetBarStyle(BarName, Result, DamageHeight)
	if DisplayMode == "full" then

		if Result == ATTACK_HIT then
			windower.prim.set_size(BarName, BarWidth, DamageHeight)
			SetBarColor(BarName, ColorHit)

		elseif Result == ATTACK_CRIT then
			windower.prim.set_size(BarName, BarWidth, DamageHeight)
			SetBarColor(BarName, ColorCrit)

		elseif Result == ATTACK_MISS then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorMiss)

		elseif Result == ATTACK_BLOCK then
			windower.prim.set_size(BarName, BarWidth, DamageHeight)
			SetBarColor(BarName, ColorBlock)

		elseif Result == ATTACK_HIT_ZERO then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorHitZero)

		elseif Result == ATTACK_HEAL then
			-- Heals do not affect the Max damage which means they can outscale
			windower.prim.set_size(BarName, BarWidth, DamageHeight)
			SetBarColor(BarName, ColorHeal)

		elseif Result == AE_NONE then
			windower.prim.set_visibility(BarName, false)

		elseif Result == AE_HIT then
			windower.prim.set_size(BarName, BarWidth, DamageHeight)
			SetBarColor(BarName, ColorAE)

		elseif Result == AE_HEAL then
			windower.prim.set_size(BarName, BarWidth, DamageHeight)
			SetBarColor(BarName, ColorAEHeal)
		end

	elseif DisplayMode == "simple" then

		if Result == ATTACK_HIT or Result == ATTACK_CRIT then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorHit)

		elseif Result == ATTACK_MISS then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorMiss)

		elseif Result == ATTACK_BLOCK then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorBlock)

		elseif Result == ATTACK_HIT_ZERO then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorHitZero)

		elseif Result == ATTACK_HEAL then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorHeal)

		elseif Result == AE_HIT or Result == AE_HEAL or Result == AE_NONE then
			windower.prim.set_visibility(BarName, false)
		end
	end
end
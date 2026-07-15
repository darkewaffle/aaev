local BarsAlpha = playersettings.BarsAlpha or 255

local ColorHit = playersettings.ColorHit or Blue
local ColorCrit = playersettings.ColorCrit or BluePale
local ColorMiss = playersettings.ColorMiss or White
local ColorBlock = playersettings.ColorBlock or Grey3
local ColorHitZero = playersettings.ColorHitZero or Grey2
local ColorCounter = playersettings.ColorCounter or Red
local ColorShadow = Grey1
ColorHeal = playersettings.ColorHeal or GreenLime
local ColorAE = playersettings.ColorAdditionalEffect or Grey1
local ColorAEHeal = playersettings.ColorAdditionalEffectHeal or GreenLime

local BarNameRoot = "AAEV_Bar"
local BarNameAE = BarNameRoot .. "_AE"

function CreateBars(Visible, ChartType)
	local NumberOfBars = 0
	local ChartX = 0
	local ChartY = 0
	local BarWidth = 0

	if ChartType == TYPE_PLAYER then
		NumberOfBars = ChartBars
		ChartX = ChartStartX
		ChartY = ChartStartY
		ChartSizeY = ChartHeight
		BarWidth = ChartWidth / ChartBars
	elseif ChartType == TYPE_PET then
		NumberOfBars = PetChartBars
		ChartX = PetChartStartX
		ChartY = PetChartStartY
		ChartSizeY = PetChartHeight
		BarWidth = PetChartWidth / PetChartBars
	else
		print("Invalid ChartType in CreateBars.")
		return
	end

	for i = 1, NumberOfBars do
		local BarName = GetBarName(ChartType, i)
		windower.prim.create(BarName)
		windower.prim.set_position(BarName, ChartX + (BarWidth * (i-1)), ChartY)
		windower.prim.set_size(BarName, BarWidth, ChartSizeY * -1)
		windower.prim.set_color(BarName, 0, 10*i, 5*i, 1*i)
		windower.prim.set_visibility(BarName, Visible)

		if AdditionalEffectStackBars then
			BarName = GetBarNameAE(ChartType, i)
			windower.prim.create(BarName)
			windower.prim.set_position(BarName, ChartX + (BarWidth * (i-1)), ChartY)
			windower.prim.set_size(BarName, BarWidth, ChartSizeY * -1)
			windower.prim.set_color(BarName, 0, 1*i, 5*i, 10*i)
			windower.prim.set_visibility(BarName, Visible)
		end

	end
end

function CreatePetBars(Visible)
	CreateBars(Visible, TYPE_PET)
end

function CreatePlayerBars(Visible)
	CreateBars(Visible, TYPE_PLAYER)
end

function UpdateBars(TargetID, ChartType)
	local NumberOfBars = 0
	local ChartX = 0
	local ChartY = 0
	local BarWidth = 0

	if ChartType == TYPE_PLAYER then
		NumberOfBars = ChartBars
		ChartX = ChartStartX
		ChartY = ChartStartY
		BarWidth = ChartWidth / ChartBars
	elseif ChartType == TYPE_PET then
		NumberOfBars = PetChartBars
		ChartX = PetChartStartX
		ChartY = PetChartStartY
		BarWidth = PetChartWidth / PetChartBars
	else
		print("Invalid ChartType in UpdateBars.")
		return
	end

	local AttackLog = GetAttackLogForType(ChartType)
	local MaxDamage = AttackLog[TargetID][ATTACK_MAX]

	for i = 1, NumberOfBars do
		local BarAttack = GetBarName(ChartType, i)
		local BarAE = GetBarNameAE(ChartType, i)

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
				DamageHeight = Clamp(math.floor(AttackDamage / MaxDamage * ChartHeight), 1, ChartHeight) * -1
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
			SetBarStyle(BarAttack, AttackResult, DamageHeight, BarWidth)


			-- If AE damage should be stacked as a second bar and AE damage > 0
			if not AdditionalEffectSingleBar and AdditionalEffectStackBars and AdditionalEffectDamage > 0 then

				windower.prim.set_visibility(BarAE, true)
				SetBarStyle(BarAE, AdditionalEffectResult, AEHeight, BarWidth)

				-- Adjust the position. Horizontal does not need changed (same as the created value), vertical position is offset by the damage height calculated for the physical hit
				windower.prim.set_position(BarAE, ChartX + (BarWidth * (i-1)), ChartY + DamageHeight)

			else
				windower.prim.set_visibility(BarAE, false)
			end

		else
			windower.prim.set_visibility(BarAttack, false)
			windower.prim.set_visibility(BarAE, false)
		end
	end

end

function UpdatePetBars(TargetID)
	UpdateBars(TargetID, TYPE_PET)
end

function UpdatePlayerBars(TargetID)
	UpdateBars(TargetID, TYPE_PLAYER)
end

function DisplayBars(Visible, ChartType)
	local NumberOfBars = 0

	if ChartType == TYPE_PLAYER then
		NumberOfBars = ChartBars

	elseif ChartType == TYPE_PET then
		NumberOfBars = PetChartBars
	else
		print("Invalid ChartType in DisplayBars.")
		return
	end

	for i = 1, NumberOfBars do
		local BarName = GetBarName(ChartType, i)
		windower.prim.set_visibility(BarName, Visible)

		if AdditionalEffectStackBars then
			BarName = GetBarNameAE(ChartType, i)
			windower.prim.set_visibility(BarName, Visible)
		end
	end
end

function DisplayPetBars(Visible)
	DisplayBars(Visible, TYPE_PET)
end

function DisplayPlayerBars(Visible)
	DisplayBars(Visible, TYPE_PLAYER)
end

function DestroyPetBars()
	local NumberOfBars = PetChartBars

	for i = 1, NumberOfBars do
		local BarAttack = GetBarName(TYPE_PET, i)
		local BarAE = GetBarNameAE(TYPE_PET, i)

		windower.prim.delete(BarAttack)
		windower.prim.delete(BarAE)
	end
end

function SetBarColor(BarName, BarColor, AlphaOverride)
	local Alpha = AlphaOverride or BarsAlpha
	windower.prim.set_color(BarName, Alpha, BarColor[1], BarColor[2], BarColor[3])
end

function SetBarStyle(BarName, Result, DamageHeight, BarWidth)
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

		elseif Result == ATTACK_COUNTER then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorCounter)

		elseif Result == ATTACK_SHADOW then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorShadow, 1)

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

		elseif Result == ATTACK_COUNTER then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorCounter)

		elseif Result == ATTACK_SHADOW then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorShadow, 1)

		elseif Result == ATTACK_HEAL then
			windower.prim.set_size(BarName, BarWidth, BarWidth)
			SetBarColor(BarName, ColorHeal)

		elseif Result == AE_HIT or Result == AE_HEAL or Result == AE_NONE then
			windower.prim.set_visibility(BarName, false)
		end
	end
end

function GetBarName(ChartType, Iterator)
	return BarNameRoot .. Iterator .. ChartType
end

function GetBarNameAE(ChartType, Iterator)
	return BarNameAE .. Iterator .. ChartType
end
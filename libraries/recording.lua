AttackLog = {}
DeadIDs = {}
LogResetPending = false

ATTACK_HIT = "hit"
ATTACK_CRIT= "crit"
ATTACK_MISS = "miss"
ATTACK_BLOCK = "block"
ATTACK_HIT_ZERO = "zero"
ATTACK_ADDITIONAL_EFFECT = "additionaleffect"

AdditionalEffectSingleBar = playersettings.AdditionalEffectSingleBar
if AdditionalEffectSingleBar == nil then
	AdditionalEffectSingleBar = false
end

AdditionalEffectStackBars = playersettings.AdditionalEffectStackBars
if AdditionalEffectStackBars == nil then
	AdditionalEffectStackBars = false
end

DisplayContinuous = playersettings.DisplayContinuous
if DisplayContinuous == nil then
	DisplayContinuous = false
end

-- If DisplayContinuous is enabled then TargetOverride will take the place of TargetID for all operations - recording every hit to a single log
if DisplayContinuous then
	TargetOverride = "ALLTARGETS"
end

function RecordAttackData(AttackPacket)
	local ActionTarget = TargetOverride or AttackPacket["Target 1 ID"]
	local AttackCount = AttackPacket["Target 1 Action Count"]
	local AttackPrefix = "Target 1 Action "

	local AdditionalEffectDamageMessages =
	{
		[161] = true, -- HP Drain
		[163] = true, -- Generic damage (?)
		[229] = true, -- Enspell damage
	}

	if not AttackLog[ActionTarget] then
		CreateAttackLog(ActionTarget)
	end

	for i = 1, AttackCount do
		local AttackName = AttackPrefix .. i
		local AttackMessage = AttackPacket[AttackName .. " Message"]
		local AttackDamage = AttackPacket[AttackName .. " Param"]
		local AttackResult = "Placeholder"

		local AdditionalEffect = AttackPacket[AttackName .. " Has Added Effect"]
		local AdditionalEffectMessage = AttackPacket[AttackName .. " Added Effect Message"]
		local AdditionalEffectDamage = 0

		-- Evaluate results of the attack
		if AttackMessage == 15 or AttackMessage == 63 then
			AttackResult = ATTACK_MISS
			AttackLog[ActionTarget][ATTACK_MISS] = AttackLog[ActionTarget][ATTACK_MISS] + 1
		elseif AttackMessage == 69 then
			AttackResult = ATTACK_BLOCK
		elseif AttackDamage == 0 then
			AttackResult = ATTACK_HIT_ZERO
		elseif AttackMessage == 67 then
			AttackResult = ATTACK_CRIT
			AttackLog[ActionTarget][ATTACK_CRIT] = AttackLog[ActionTarget][ATTACK_CRIT] + 1
		else
			AttackResult = ATTACK_HIT
		end

		-- Evaluate if an Additional Effect was applied and dealt damage
		if AdditionalEffect then
			if AdditionalEffectDamageMessages[AdditionalEffectMessage] then
				AdditionalEffectDamage = AttackPacket[AttackName .. " Added Effect Param"] or 0
			end
		end

		-- If either AE setting is enabled then max damage should reflect hit + AE
		if AdditionalEffectSingleBar or AdditionalEffectStackBars then
			AttackLog[ActionTarget]["max"] = math.max(AttackLog[ActionTarget]["max"], AttackDamage + AdditionalEffectDamage)
		else
			AttackLog[ActionTarget]["max"] = math.max(AttackLog[ActionTarget]["max"], AttackDamage)
		end

		-- Update the table with the attack data
		AttackLog[ActionTarget]["count"] = AttackLog[ActionTarget]["count"] + 1
		table.insert(AttackLog[ActionTarget], {result = AttackResult, damage = AttackDamage, additionaleffect = AdditionalEffectDamage})
	end
end

function TrimAttackLog(TargetID)
	local TargetLog = AttackLog[TargetID]

	if TargetLog then
		if #TargetLog > ChartBars then
			local BarsRangeStart = #TargetLog - ChartBars + 1
			local j = 1

			for i = BarsRangeStart, #TargetLog do
				TargetLog[j] = TargetLog[i]
				TargetLog[i] = nil
				j = j + 1
			end
		end
	end
end

function CreateAttackLog(TargetID)
	AttackLog[TargetID] =
		{
			["count"] = 0,
			["max"] = 0,
			[ATTACK_MISS] = 0,
			[ATTACK_CRIT] = 0
		}
end

function ResetAttackData()
	for TargetID, _ in pairs(DeadIDs) do
		AttackLog[TargetID] = nil
		DeadIDs[TargetID] = nil
	end

	LogResetPending = false
end

function ResetAttackLog()
	AttackLog = {}
end

function CreateDemoLog()
	local DemoMax = 125

	if AdditionalEffectSingleBar or AdditionalEffectStackBars then
		DemoMax = 135
	end

	AttackLog[1] =
	{
		["count"] = 100,
		["max"] = DemoMax,
		[ATTACK_MISS] = 16,
		[ATTACK_CRIT] = 21,
		[1] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[2] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[3] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=10},
		[4] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=10},
		[5] = {result=ATTACK_HIT, damage=45, additionaleffect=10},
		[6] = {result=ATTACK_CRIT, damage=55, additionaleffect=10},
		[7] = {result=ATTACK_HIT, damage=65, additionaleffect=10},
		[8] = {result=ATTACK_HIT, damage=75, additionaleffect=20},
		[9] = {result=ATTACK_BLOCK, damage=25, additionaleffect=20},
		[10] = {result=ATTACK_BLOCK, damage=25, additionaleffect=0},
		[11] = {result=ATTACK_HIT, damage=105, additionaleffect=0},
		[12] = {result=ATTACK_CRIT, damage=115, additionaleffect=0},
		[13] = {result=ATTACK_HIT, damage=125, additionaleffect=0},
		[14] = {result=ATTACK_HIT, damage=115, additionaleffect=0},
		[15] = {result=ATTACK_CRIT, damage=105, additionaleffect=0},
		[16] = {result=ATTACK_BLOCK, damage=35, additionaleffect=0},
		[17] = {result=ATTACK_BLOCK, damage=15, additionaleffect=0},
		[18] = {result=ATTACK_CRIT, damage=75, additionaleffect=0},
		[19] = {result=ATTACK_HIT, damage=65, additionaleffect=0},
		[20] = {result=ATTACK_HIT, damage=55, additionaleffect=0},
		[21] = {result=ATTACK_CRIT, damage=45, additionaleffect=0},
		[22] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[23] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[24] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=10},
		[25] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=10},
		[26] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[27] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[28] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=10},
		[29] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=10},
		[30] = {result=ATTACK_HIT, damage=45, additionaleffect=10},
		[31] = {result=ATTACK_CRIT, damage=55, additionaleffect=10},
		[32] = {result=ATTACK_HIT, damage=65, additionaleffect=10},
		[33] = {result=ATTACK_HIT, damage=75, additionaleffect=25},
		[34] = {result=ATTACK_BLOCK, damage=25, additionaleffect=25},
		[35] = {result=ATTACK_BLOCK, damage=25, additionaleffect=10},
		[36] = {result=ATTACK_HIT, damage=105, additionaleffect=10},
		[37] = {result=ATTACK_CRIT, damage=115, additionaleffect=10},
		[38] = {result=ATTACK_HIT, damage=125, additionaleffect=10},
		[39] = {result=ATTACK_HIT, damage=115, additionaleffect=10},
		[40] = {result=ATTACK_CRIT, damage=105, additionaleffect=10},
		[41] = {result=ATTACK_BLOCK, damage=35, additionaleffect=10},
		[42] = {result=ATTACK_BLOCK, damage=15, additionaleffect=10},
		[43] = {result=ATTACK_CRIT, damage=75, additionaleffect=10},
		[44] = {result=ATTACK_HIT, damage=65, additionaleffect=0},
		[45] = {result=ATTACK_HIT, damage=55, additionaleffect=0},
		[46] = {result=ATTACK_CRIT, damage=45, additionaleffect=0},
		[47] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[48] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[49] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=0},
		[50] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=0},
		[51] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[52] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[53] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=0},
		[54] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=0},
		[55] = {result=ATTACK_HIT, damage=45, additionaleffect=0},
		[56] = {result=ATTACK_CRIT, damage=55, additionaleffect=0},
		[57] = {result=ATTACK_HIT, damage=65, additionaleffect=10},
		[58] = {result=ATTACK_HIT, damage=75, additionaleffect=10},
		[59] = {result=ATTACK_BLOCK, damage=25, additionaleffect=10},
		[60] = {result=ATTACK_BLOCK, damage=25, additionaleffect=10},
		[61] = {result=ATTACK_HIT, damage=105, additionaleffect=10},
		[62] = {result=ATTACK_CRIT, damage=115, additionaleffect=10},
		[63] = {result=ATTACK_HIT, damage=125, additionaleffect=10},
		[64] = {result=ATTACK_HIT, damage=115, additionaleffect=10},
		[65] = {result=ATTACK_CRIT, damage=105, additionaleffect=10},
		[66] = {result=ATTACK_BLOCK, damage=35, additionaleffect=10},
		[67] = {result=ATTACK_BLOCK, damage=15, additionaleffect=10},
		[68] = {result=ATTACK_CRIT, damage=75, additionaleffect=10},
		[69] = {result=ATTACK_HIT, damage=65, additionaleffect=10},
		[70] = {result=ATTACK_HIT, damage=55, additionaleffect=10},
		[71] = {result=ATTACK_CRIT, damage=45, additionaleffect=0},
		[72] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[73] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[74] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=0},
		[75] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=0},
		[76] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[77] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[78] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=0},
		[79] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=0},
		[80] = {result=ATTACK_HIT, damage=45, additionaleffect=0},
		[81] = {result=ATTACK_CRIT, damage=55, additionaleffect=0},
		[82] = {result=ATTACK_HIT, damage=65, additionaleffect=0},
		[83] = {result=ATTACK_HIT, damage=75, additionaleffect=0},
		[84] = {result=ATTACK_BLOCK, damage=25, additionaleffect=0},
		[85] = {result=ATTACK_BLOCK, damage=25, additionaleffect=0},
		[86] = {result=ATTACK_HIT, damage=105, additionaleffect=0},
		[87] = {result=ATTACK_CRIT, damage=115, additionaleffect=10},
		[88] = {result=ATTACK_HIT, damage=125, additionaleffect=10},
		[89] = {result=ATTACK_HIT, damage=115, additionaleffect=10},
		[90] = {result=ATTACK_CRIT, damage=105, additionaleffect=10},
		[91] = {result=ATTACK_BLOCK, damage=35, additionaleffect=10},
		[92] = {result=ATTACK_BLOCK, damage=15, additionaleffect=10},
		[93] = {result=ATTACK_CRIT, damage=75, additionaleffect=10},
		[94] = {result=ATTACK_HIT, damage=65, additionaleffect=10},
		[95] = {result=ATTACK_HIT, damage=55, additionaleffect=10},
		[96] = {result=ATTACK_CRIT, damage=45, additionaleffect=10},
		[97] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[98] = {result=ATTACK_MISS, damage=0, additionaleffect=0},
		[99] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=10},
		[100] = {result=ATTACK_HIT_ZERO, damage=0, additionaleffect=10}
	}
end
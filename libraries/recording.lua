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

function RecordAttackData(AttackPacket)
	local ActionTarget = AttackPacket["Target 1 ID"]
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
	AttackLog[1] =
	{
		["count"] = 100,
		["max"] = 125,
		[ATTACK_MISS] = 16,
		[ATTACK_CRIT] = 21,
		[1] = {result=ATTACK_MISS, damage=0},
		[2] = {result=ATTACK_MISS, damage=0},
		[3] = {result=ATTACK_HIT_ZERO, damage=0},
		[4] = {result=ATTACK_HIT_ZERO, damage=0},
		[5] = {result=ATTACK_HIT, damage=45},
		[6] = {result=ATTACK_CRIT, damage=55},
		[7] = {result=ATTACK_HIT, damage=65},
		[8] = {result=ATTACK_HIT, damage=75},
		[9] = {result=ATTACK_BLOCK, damage=25},
		[10] = {result=ATTACK_BLOCK, damage=25},
		[11] = {result=ATTACK_HIT, damage=105},
		[12] = {result=ATTACK_CRIT, damage=115},
		[13] = {result=ATTACK_HIT, damage=125},
		[14] = {result=ATTACK_HIT, damage=115},
		[15] = {result=ATTACK_CRIT, damage=105},
		[16] = {result=ATTACK_BLOCK, damage=35},
		[17] = {result=ATTACK_BLOCK, damage=15},
		[18] = {result=ATTACK_CRIT, damage=75},
		[19] = {result=ATTACK_HIT, damage=65},
		[20] = {result=ATTACK_HIT, damage=55},
		[21] = {result=ATTACK_CRIT, damage=45},
		[22] = {result=ATTACK_MISS, damage=0},
		[23] = {result=ATTACK_MISS, damage=0},
		[24] = {result=ATTACK_HIT_ZERO, damage=0},
		[25] = {result=ATTACK_HIT_ZERO, damage=0},
		[26] = {result=ATTACK_MISS, damage=0},
		[27] = {result=ATTACK_MISS, damage=0},
		[28] = {result=ATTACK_HIT_ZERO, damage=0},
		[29] = {result=ATTACK_HIT_ZERO, damage=0},
		[30] = {result=ATTACK_HIT, damage=45},
		[31] = {result=ATTACK_CRIT, damage=55},
		[32] = {result=ATTACK_HIT, damage=65},
		[33] = {result=ATTACK_HIT, damage=75},
		[34] = {result=ATTACK_BLOCK, damage=25},
		[35] = {result=ATTACK_BLOCK, damage=25},
		[36] = {result=ATTACK_HIT, damage=105},
		[37] = {result=ATTACK_CRIT, damage=115},
		[38] = {result=ATTACK_HIT, damage=125},
		[39] = {result=ATTACK_HIT, damage=115},
		[40] = {result=ATTACK_CRIT, damage=105},
		[41] = {result=ATTACK_BLOCK, damage=35},
		[42] = {result=ATTACK_BLOCK, damage=15},
		[43] = {result=ATTACK_CRIT, damage=75},
		[44] = {result=ATTACK_HIT, damage=65},
		[45] = {result=ATTACK_HIT, damage=55},
		[46] = {result=ATTACK_CRIT, damage=45},
		[47] = {result=ATTACK_MISS, damage=0},
		[48] = {result=ATTACK_MISS, damage=0},
		[49] = {result=ATTACK_HIT_ZERO, damage=0},
		[50] = {result=ATTACK_HIT_ZERO, damage=0},
		[51] = {result=ATTACK_MISS, damage=0},
		[52] = {result=ATTACK_MISS, damage=0},
		[53] = {result=ATTACK_HIT_ZERO, damage=0},
		[54] = {result=ATTACK_HIT_ZERO, damage=0},
		[55] = {result=ATTACK_HIT, damage=45},
		[56] = {result=ATTACK_CRIT, damage=55},
		[57] = {result=ATTACK_HIT, damage=65},
		[58] = {result=ATTACK_HIT, damage=75},
		[59] = {result=ATTACK_BLOCK, damage=25},
		[60] = {result=ATTACK_BLOCK, damage=25},
		[61] = {result=ATTACK_HIT, damage=105},
		[62] = {result=ATTACK_CRIT, damage=115},
		[63] = {result=ATTACK_HIT, damage=125},
		[64] = {result=ATTACK_HIT, damage=115},
		[65] = {result=ATTACK_CRIT, damage=105},
		[66] = {result=ATTACK_BLOCK, damage=35},
		[67] = {result=ATTACK_BLOCK, damage=15},
		[68] = {result=ATTACK_CRIT, damage=75},
		[69] = {result=ATTACK_HIT, damage=65},
		[70] = {result=ATTACK_HIT, damage=55},
		[71] = {result=ATTACK_CRIT, damage=45},
		[72] = {result=ATTACK_MISS, damage=0},
		[73] = {result=ATTACK_MISS, damage=0},
		[74] = {result=ATTACK_HIT_ZERO, damage=0},
		[75] = {result=ATTACK_HIT_ZERO, damage=0},
		[76] = {result=ATTACK_MISS, damage=0},
		[77] = {result=ATTACK_MISS, damage=0},
		[78] = {result=ATTACK_HIT_ZERO, damage=0},
		[79] = {result=ATTACK_HIT_ZERO, damage=0},
		[80] = {result=ATTACK_HIT, damage=45},
		[81] = {result=ATTACK_CRIT, damage=55},
		[82] = {result=ATTACK_HIT, damage=65},
		[83] = {result=ATTACK_HIT, damage=75},
		[84] = {result=ATTACK_BLOCK, damage=25},
		[85] = {result=ATTACK_BLOCK, damage=25},
		[86] = {result=ATTACK_HIT, damage=105},
		[87] = {result=ATTACK_CRIT, damage=115},
		[88] = {result=ATTACK_HIT, damage=125},
		[89] = {result=ATTACK_HIT, damage=115},
		[90] = {result=ATTACK_CRIT, damage=105},
		[91] = {result=ATTACK_BLOCK, damage=35},
		[92] = {result=ATTACK_BLOCK, damage=15},
		[93] = {result=ATTACK_CRIT, damage=75},
		[94] = {result=ATTACK_HIT, damage=65},
		[95] = {result=ATTACK_HIT, damage=55},
		[96] = {result=ATTACK_CRIT, damage=45},
		[97] = {result=ATTACK_MISS, damage=0},
		[98] = {result=ATTACK_MISS, damage=0},
		[99] = {result=ATTACK_HIT_ZERO, damage=0},
		[100] = {result=ATTACK_HIT_ZERO, damage=0}
	}
end
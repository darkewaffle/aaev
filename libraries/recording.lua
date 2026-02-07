AttackLog = {}
DeadIDs = {}
LogResetPending = false

ATTACK_HIT = "hit"
ATTACK_CRIT= "crit"
ATTACK_MISS = "miss"
ATTACK_BLOCK = "block"
ATTACK_HIT_ZERO = "zero"
ATTACK_HEAL = "heal"
AE_HIT = "ae_hit"
AE_HEAL = "ae_heal"
AE_NONE = "ae_none"


ATTACK_RESULT = "attack_result"
ATTACK_DAMAGE = "attack_damage"
AE_RESULT = "ae_result"
AE_DAMAGE = "ae_damage"
ATTACK_COUNT = "attack_count"
ATTACK_MAX = "attack_max"

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

local AttackMessageMap =
	{
		[1] = ATTACK_HIT,
		[15] = ATTACK_MISS,
		[63] = ATTACK_MISS,
		[67] = ATTACK_CRIT,
		[69] = ATTACK_BLOCK,
		[373] = ATTACK_HEAL
	}

local AdditionalEffectMessageMap =
	{
		--[161] = AE_HIT, -- HP Drain, used by Samba which does not deal damage. Unknown if other sources that do.
		[163] = AE_HIT, -- Generic damage (?)
		--[167] = ?			-- heals the player, not target?
		[229] = AE_HIT, -- Enspell damage
		[384] = AE_HEAL -- enspell heal?
	}	

function RecordAttackData(AttackPacket)
	local ActionTarget = TargetOverride or AttackPacket["Target 1 ID"]
	local AttackCount = AttackPacket["Target 1 Action Count"]
	local AttackPrefix = "Target 1 Action "

	if not AttackLog[ActionTarget] then
		CreateAttackLog(ActionTarget)
	end

	for i = 1, AttackCount do
		-- Evaluate the physical hit
		local AttackName = AttackPrefix .. i
		local AttackMessage = AttackPacket[AttackName .. " Message"]
		local AttackDamage = AttackPacket[AttackName .. " Param"]
		local AttackResult = AttackMessageMap[AttackMessage] or ATTACK_HIT

		if AttackResult == ATTACK_MISS then
			AttackLog[ActionTarget][ATTACK_MISS] = AttackLog[ActionTarget][ATTACK_MISS] + 1
		elseif AttackResult == ATTACK_CRIT then
			AttackLog[ActionTarget][ATTACK_CRIT] = AttackLog[ActionTarget][ATTACK_CRIT] + 1
		end

		if AttackResult ~= ATTACK_MISS and AttackDamage == 0 then
			AttackResult = ATTACK_HIT_ZERO
		end

		-- Evaluate any additional effect damage
		local AdditionalEffect = AttackPacket[AttackName .. " Has Added Effect"]
		local AdditionalEffectMessage = AttackPacket[AttackName .. " Added Effect Message"]
		local AdditionalEffectDamage = AttackPacket[AttackName .. " Added Effect Param"] or 0
		local AdditionalEffectResult = AdditionalEffectMessageMap[AdditionalEffectMessage] or AE_NONE


		local TotalDamage = 0
		-- Attacks that heal do not count as dealing damage. Plus healing can sometimes be subject to a multiplier and throw off the chart scale.
		if AttackResult ~= ATTACK_HEAL then
			TotalDamage = TotalDamage + AttackDamage
		end

		-- Only include Additional Effect damage in the damage total if an Additional Effect setting is enabled and the Additional Effect did not heal
		if (AdditionalEffectSingleBar or AdditionalEffectStackBars) and AdditionalEffectResult ~= AE_HEAL then
			TotalDamage = TotalDamage + AdditionalEffectDamage
		end

		-- Update the table with the attack data
		AttackLog[ActionTarget][ATTACK_MAX] = math.max(AttackLog[ActionTarget][ATTACK_MAX], TotalDamage)
		AttackLog[ActionTarget][ATTACK_COUNT] = AttackLog[ActionTarget][ATTACK_COUNT] + 1

		table.insert(AttackLog[ActionTarget], {[ATTACK_RESULT] = AttackResult, [ATTACK_DAMAGE] = AttackDamage, [AE_RESULT] = AdditionalEffectResult, [AE_DAMAGE] = AdditionalEffectDamage})
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
			[ATTACK_COUNT] = 0,
			[ATTACK_MAX] = 0,
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
		[ATTACK_COUNT] = 100,
		[ATTACK_MAX] = DemoMax,
		[ATTACK_MISS] = 16,
		[ATTACK_CRIT] = 21,
		[1] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[2] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[3] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[4] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[5] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=45, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[6] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=55, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[7] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=65, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[8] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=75, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=20},
		[9] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=25, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=20},
		[10] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=25, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[11] = {[ATTACK_RESULT]=ATTACK_HEAL, [ATTACK_DAMAGE]=105, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[12] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=115, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[13] = {[ATTACK_RESULT]=ATTACK_HEAL, [ATTACK_DAMAGE]=5000, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[14] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=115, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[15] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=105, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[16] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=35, [AE_RESULT]=AE_HEAL, [AE_DAMAGE]=50},
		[17] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=15, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[18] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=75, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[19] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=65, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[20] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=55, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[21] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=45, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[22] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[23] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[24] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[25] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[26] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[27] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[28] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[29] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[30] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=45, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[31] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=55, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[32] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=65, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[33] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=75, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=25},
		[34] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=25, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=25},
		[35] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=25, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[36] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=105, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[37] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=115, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[38] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=125, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[39] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=115, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[40] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=105, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[41] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=35, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[42] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=15, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[43] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=75, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[44] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=65, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[45] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=55, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[46] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=45, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[47] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[48] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[49] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[50] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[51] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[52] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[53] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[54] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[55] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=45, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[56] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=55, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[57] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=65, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[58] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=75, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[59] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=25, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[60] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=25, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[61] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=105, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[62] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=115, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[63] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=125, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[64] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=115, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[65] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=105, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[66] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=35, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[67] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=15, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[68] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=75, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[69] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=65, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[70] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=55, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[71] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=45, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[72] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[73] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[74] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[75] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[76] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[77] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[78] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[79] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[80] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=45, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[81] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=55, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[82] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=65, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[83] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=75, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[84] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=25, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[85] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=25, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[86] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=105, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[87] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=115, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[88] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=125, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[89] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=115, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[90] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=105, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[91] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=35, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[92] = {[ATTACK_RESULT]=ATTACK_BLOCK, [ATTACK_DAMAGE]=15, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[93] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=75, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[94] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=65, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[95] = {[ATTACK_RESULT]=ATTACK_HIT, [ATTACK_DAMAGE]=55, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[96] = {[ATTACK_RESULT]=ATTACK_CRIT, [ATTACK_DAMAGE]=45, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[97] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[98] = {[ATTACK_RESULT]=ATTACK_MISS, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_NONE, [AE_DAMAGE]=0},
		[99] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10},
		[100] = {[ATTACK_RESULT]=ATTACK_HIT_ZERO, [ATTACK_DAMAGE]=0, [AE_RESULT]=AE_HIT, [AE_DAMAGE]=10}
	}
end
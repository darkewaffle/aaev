PlayerAttackLog = {}
PetAttackLog = {}
DeadIDs = {}
LogResetPending = false

TYPE_PLAYER = "player"
TYPE_PET = "pet"

ATTACK_HIT = "hit"
ATTACK_CRIT= "crit"
ATTACK_MISS = "miss"
ATTACK_BLOCK = "block"
ATTACK_HIT_ZERO = "zero"
ATTACK_HEAL = "heal"
ATTACK_SHADOW = "shadow"
ATTACK_COUNTER = "counter"

AE_HIT = "ae_hit"
AE_HEAL = "ae_heal"
AE_TREASURE_HUNTER = "ae_treasure_hunter"
AE_NONE = "ae_none"


ATTACK_RESULT = "attack_result"
ATTACK_DAMAGE = "attack_damage"
AE_RESULT = "ae_result"
AE_DAMAGE = "ae_damage"
ATTACK_COUNT = "attack_count"
ATTACK_MAX = "attack_max"
TREASURE_HUNTER_LEVEL = "treasure_hunter_level"

WEAPON_SKILL_LOG = "ws_log"
WS_NAME = "ws_name"
WS_DAMAGE = "ws_damage"
WS_RESULT = "ws_result"
SC_NAME = "sc_name"
SC_DAMAGE = "sc_damage"
SC_RESULT = "sc_result"

local TARGET_OVERRIDE = 0

RecordedWSCount = playersettings.WeaponskillCount or 5
PetRecordedWSCount = playersettings.PetWeaponskillCount or 5

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
		[1] = ATTACK_HIT,			-- Hit
		[14] = ATTACK_COUNTER,		-- Counter
		[15] = ATTACK_MISS,			-- Miss
		[31] = ATTACK_SHADOW,		-- Shadow
		[33] = ATTACK_COUNTER,		-- Counter
		[63] = ATTACK_MISS,			-- Miss
		[67] = ATTACK_CRIT,			-- Crit
		[69] = ATTACK_BLOCK,		-- Block
		[70] = ATTACK_BLOCK,		-- Parry
		[373] = ATTACK_HEAL,		-- Hit that heals
		[606] = ATTACK_COUNTER		-- Counter
	}

local AdditionalEffectMessageMap =
	{
		--[161] = AE_HIT, -- HP Drain, used by Samba which does not deal damage. Unknown if other sources that do.
		[163] = AE_HIT, -- Generic damage (?)
		--[167] = ?			-- heals the player, not target?
		[229] = AE_HIT, -- Enspell damage
		[384] = AE_HEAL, -- enspell heal?
		[603] = AE_TREASURE_HUNTER
	}	

function ResetAttackData()
	for TargetID, _ in pairs(DeadIDs) do
		PlayerAttackLog[TargetID] = nil
		PetAttackLog[TargetID] = nil
		DeadIDs[TargetID] = nil
	end

	LogResetPending = false
end

function ResetAttackLogs()
	PlayerAttackLog = {}
	PetAttackLog = {}
end

function GetTargetOverride()
	if TargetOverride ~= 0 then
		return TargetOverride
	else
		return nil
	end
end

function GetLogForType(LogType)
	if LogType == TYPE_PLAYER then
		return PlayerAttackLog
	elseif LogType == TYPE_PET then
		return PetAttackLog
	else
		print("Error, invalid argument to GetLogForType.")
		return nil
	end
end

function RecordAttackData(AttackPacket, LogType)
	local AttackLog = GetLogForType(LogType)
	if not AttackLog then
		print("Invalid AttackLog for RecordAttackData")
		return
	end

	local ActionTarget = GetTargetOverride() or AttackPacket["Target 1 ID"]
	local AttackCount = AttackPacket["Target 1 Action Count"]
	local AttackPrefix = "Target 1 Action "

	if not AttackLog[ActionTarget] then
		CreateAttackLog(ActionTarget, AttackLog)
	end

	for i = 1, AttackCount do
		-- Evaluate the physical hit
		local AttackName = AttackPrefix .. i
		local AttackMessage = AttackPacket[AttackName .. " Message"]
		local AttackDamage = AttackPacket[AttackName .. " Param"]
		local AttackResult = AttackMessageMap[AttackMessage] or ATTACK_HIT

		-- Attacks that are countered have no attack message but do have a Spike Effect message representing a Counter
		if AttackMessage == 0 then
			local SpikeMessage = AttackPacket[AttackName .. " Spike Effect Message"]
			AttackResult = AttackMessageMap[SpikeMessage] or ATTACK_HIT
			AttackDamage = 0
		end

		if AttackResult == ATTACK_MISS then
			AttackLog[ActionTarget][ATTACK_MISS] = AttackLog[ActionTarget][ATTACK_MISS] + 1
		elseif AttackResult == ATTACK_CRIT then
			AttackLog[ActionTarget][ATTACK_CRIT] = AttackLog[ActionTarget][ATTACK_CRIT] + 1
		end

		if AttackResult ~= ATTACK_MISS and AttackResult ~= ATTACK_COUNTER and AttackDamage == 0 then
			AttackResult = ATTACK_HIT_ZERO
		end

		-- Evaluate any additional effect damage
		local AdditionalEffect = AttackPacket[AttackName .. " Has Added Effect"]
		local AdditionalEffectMessage = AttackPacket[AttackName .. " Added Effect Message"]
		local AdditionalEffectDamage = AttackPacket[AttackName .. " Added Effect Param"] or 0
		local AdditionalEffectResult = AdditionalEffectMessageMap[AdditionalEffectMessage] or AE_NONE


		-- If the additional effect was a treasure hunter increase proc then the param value (normally considered damage)
		-- instead represents the new treasure hunter level. Update the AdditionalEffectResult so it is not incorrectly treated as
		-- a damaging hit and instead record the damage
		if AdditionalEffectResult == AE_TREASURE_HUNTER then
			AttackLog[ActionTarget][TREASURE_HUNTER_LEVEL] = AdditionalEffectDamage
			AdditionalEffectResult = AE_NONE
			AdditionalEffectDamage = 0
		end

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

function RecordPetAttack(AttackPacket)
	RecordAttackData(AttackPacket, TYPE_PET)
end

function RecordPlayerAttack(AttackPacket)
	RecordAttackData(AttackPacket, TYPE_PLAYER)
end

function CreateAttackLog(TargetID, TargetLog)
	TargetLog[TargetID] =
		{
			[ATTACK_COUNT] = 0,
			[ATTACK_MAX] = 0,
			[ATTACK_MISS] = 0,
			[ATTACK_CRIT] = 0,
			[TREASURE_HUNTER_LEVEL] = 0,
			[WEAPON_SKILL_LOG] = {}
		}
end

function GetPlayerAttackLog()
	return PlayerAttackLog
end

function GetPetAttackLog()
	return PetAttackLog
end

function GetAttackLogForType(LogType)
	if LogType == TYPE_PLAYER then
		return PlayerAttackLog
	elseif LogType == TYPE_PET then
		return PetAttackLog
	else
		print("Invalid type in GetAttackLogForType")
		return nil
	end
end

function TrimAttackLog(TargetID, LogType)
	local AttackLog = GetLogForType(LogType)
	if not AttackLog then
		print("Invalid AttackLog for TrimAttackLog")
		return
	end

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

function TrimPetAttackLog(TargetID)
	TrimAttackLog(TargetID, TYPE_PET)
end

function TrimPlayerAttackLog(TargetID)
	TrimAttackLog(TargetID, TYPE_PLAYER)
end

function RecordWSData(WSPacket, LogType)
	local AttackLog = GetLogForType(LogType)
	if not AttackLog then
		print("Invalid AttackLog for RecordWSData")
		return
	end

	local ActionTarget = GetTargetOverride() or WSPacket["Target 1 ID"]
	local AttackPrefix = "Target 1 Action "

	if not AttackLog[ActionTarget] then
		CreateAttackLog(ActionTarget, AttackLog)
	end

	local AttackMessageID = WSPacket["Target 1 Action 1 Message"] 

	if MAP_WS_MESSAGES[AttackMessageID] then

		local WSID = WSPacket["Param"]
		local WSName = "WSName"

		if WSID > 0 and WSID <= 255 then
			WSName = WINDOWER_RESOURCES.weapon_skills[WSID].en
		elseif WSID >= 257 then
			WSName = WINDOWER_RESOURCES.monster_abilities[WSID].en
		end

		local WSDamage = WSPacket["Target 1 Action 1 Param"]
		local WSResult = MAP_WS_MESSAGES[AttackMessageID]
		local SkillchainPresent = WSPacket["Target 1 Action 1 Has Added Effect"]

		if SkillchainPresent then
			local SCMessage = WSPacket["Target 1 Action 1 Added Effect Message"]
			SCName = MAP_SKILLCHAIN_MESSAGES[SCMessage].name
			SCDamage = WSPacket["Target 1 Action 1 Added Effect Param"]
			SCResult = MAP_SKILLCHAIN_MESSAGES[SCMessage].result
		else
			SCName = nil
			SCDamage = nil
			SCResult = nil
		end

		table.insert(AttackLog[ActionTarget][WEAPON_SKILL_LOG], {[WS_NAME] = WSName, [WS_DAMAGE] = WSDamage, [WS_RESULT] = WSResult, [SC_NAME] = SCName, [SC_DAMAGE] = SCDamage, [SC_RESULT] = SCResult})
	end
end

function RecordPetWS(WSPacket)
	RecordWSData(WSPacket, TYPE_PET)
end

function RecordPlayerWS(WSPacket)
	RecordWSData(WSPacket, TYPE_PLAYER)
end

function RecordAvatarWS(WSPacket)
	local AttackLog = GetPetAttackLog()
	local ActionTarget = GetTargetOverride() or WSPacket["Target 1 ID"]
	local AttackPrefix = "Target 1 Action "

	if not AttackLog[ActionTarget] then
		CreateAttackLog(ActionTarget, AttackLog)
	end

	local AttackMessageID = WSPacket["Target 1 Action 1 Message"]

	if MAP_BLOODPACT_MESSAGES[AttackMessageID] then

		local WSID = WSPacket["Param"]
		local WSName = WINDOWER_RESOURCES.job_abilities[WSID].en
		local WSDamage = WSPacket["Target 1 Action 1 Param"]
		local WSResult = MAP_BLOODPACT_MESSAGES[AttackMessageID]
		local SkillchainPresent = WSPacket["Target 1 Action 1 Has Added Effect"]

		if SkillchainPresent then
			local SCMessage = WSPacket["Target 1 Action 1 Added Effect Message"]
			SCName = MAP_SKILLCHAIN_MESSAGES[SCMessage].name
			SCDamage = WSPacket["Target 1 Action 1 Added Effect Param"]
			SCResult = MAP_SKILLCHAIN_MESSAGES[SCMessage].result
		else
			SCName = nil
			SCDamage = nil
			SCResult = nil
		end

		table.insert(AttackLog[ActionTarget][WEAPON_SKILL_LOG], {[WS_NAME] = WSName, [WS_DAMAGE] = WSDamage, [WS_RESULT] = WSResult, [SC_NAME] = SCName, [SC_DAMAGE] = SCDamage, [SC_RESULT] = SCResult})
	end
end

function TrimWSLog(TargetID, LogType)
	local AttackLog = GetLogForType(LogType)
	if not AttackLog then
		print("Invalid AttackLog for TrimWSLog")
		return
	end

	local WSRecords = 0

	if LogType == TYPE_PLAYER then
		WSRecords = RecordedWSCount
	elseif LogType == TYPE_PET then
		WSRecords = PetRecordedWSCount
	end

	local TargetLog = AttackLog[TargetID][WEAPON_SKILL_LOG]

	if TargetLog then
		if #TargetLog > WSRecords then
			local WSStart = #TargetLog - WSRecords + 1
			local j = 1

			for i = WSStart, #TargetLog do
				TargetLog[j] = TargetLog[i]
				TargetLog[i] = nil
				j = j + 1
			end
		end
	end
end

function TrimPetWSLog(TargetID)
	TrimWSLog(TargetID, TYPE_PET)
end

function TrimPlayerWSLog(TargetID)
	TrimWSLog(TargetID, TYPE_PLAYER)
end


function CreateDemoLogs()
	local DemoMax = 125

	if AdditionalEffectSingleBar or AdditionalEffectStackBars then
		DemoMax = 135
	end

	PlayerAttackLog[1] =
	{
		[ATTACK_COUNT] = 100,
		[ATTACK_MAX] = DemoMax,
		[ATTACK_MISS] = 16,
		[ATTACK_CRIT] = 21,
		[TREASURE_HUNTER_LEVEL] = 5,
		[WEAPON_SKILL_LOG] = 
			{
				[1] = {[WS_NAME] = "Evisceration", [WS_DAMAGE] = 1500, [WS_RESULT] = ATTACK_HIT},
				[2] = {[WS_NAME] = "Rudra's Storm", [WS_DAMAGE] = 2000, [WS_RESULT] = ATTACK_HEAL, [SC_NAME] = "Darkness", [SC_DAMAGE] = 5000, [SC_RESULT] = ATTACK_HIT},
				[3] = {[WS_NAME] = "Rudra's Storm", [WS_DAMAGE] = 3000, [WS_RESULT] = ATTACK_HIT, [SC_NAME] = "Darkness", [SC_DAMAGE] = 10000, [SC_RESULT] = ATTACK_HEAL},
				[4] = {[WS_NAME] = "Viper Bite", [WS_DAMAGE] = 666, [WS_RESULT] = ATTACK_HIT},
				[5] = {[WS_NAME] = "Viper Bite", [WS_DAMAGE] = 99999, [WS_RESULT] = ATTACK_HIT, [SC_NAME] = "Scission", [SC_DAMAGE] = 123, [SC_RESULT] = ATTACK_HIT}
			},
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

PetAttackLog[1] =
	{
		[ATTACK_COUNT] = 100,
		[ATTACK_MAX] = DemoMax,
		[ATTACK_MISS] = 16,
		[ATTACK_CRIT] = 21,
		[TREASURE_HUNTER_LEVEL] = 5,
		[WEAPON_SKILL_LOG] = 
			{
				[1] = {[WS_NAME] = "Bone Crusher", [WS_DAMAGE] = 1500, [WS_RESULT] = ATTACK_HIT},
				[2] = {[WS_NAME] = "String Shredder", [WS_DAMAGE] = 2000, [WS_RESULT] = ATTACK_HEAL, [SC_NAME] = "Distortion", [SC_DAMAGE] = 5000, [SC_RESULT] = ATTACK_HIT},
				[3] = {[WS_NAME] = "Eclipse Bite", [WS_DAMAGE] = 3000, [WS_RESULT] = ATTACK_HIT, [SC_NAME] = "Darkness", [SC_DAMAGE] = 10000, [SC_RESULT] = ATTACK_HEAL},
				[4] = {[WS_NAME] = "Sensilla Blades", [WS_DAMAGE] = 666, [WS_RESULT] = ATTACK_HIT},
				[5] = {[WS_NAME] = "Tegmina Buffet", [WS_DAMAGE] = 99999, [WS_RESULT] = ATTACK_HIT, [SC_NAME] = "Detonation", [SC_DAMAGE] = 123, [SC_RESULT] = ATTACK_HIT}
			},
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
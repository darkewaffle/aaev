AttackLog = {}
DeadIDs = {}
LogResetPending = false

ATTACK_HIT = "hit"
ATTACK_CRIT= "crit"
ATTACK_MISS = "miss"
ATTACK_BLOCK = "block"
ATTACK_HIT_ZERO = "zero"

function RecordAttackData(AttackPacket)
	local ActionTarget = AttackPacket["Target 1 ID"]
	local AttackCount = AttackPacket["Target 1 Action Count"]
	local AttackPrefix = "Target 1 Action "

	if not AttackLog[ActionTarget] then
		CreateAttackLog(ActionTarget)
	end

	for i = 1, AttackCount do
		local AttackName = AttackPrefix .. i
		local AttackMessage = AttackPacket[AttackName .. " Message"]
		local AttackDamage = AttackPacket[AttackName .. " Param"]
		local AttackResult = "Placeholder"

		AttackLog[ActionTarget]["count"] = AttackLog[ActionTarget]["count"] + 1
		AttackLog[ActionTarget]["max"] = math.max(AttackLog[ActionTarget]["max"], AttackDamage)
		
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

		table.insert(AttackLog[ActionTarget], {result = AttackResult, damage = AttackDamage})
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
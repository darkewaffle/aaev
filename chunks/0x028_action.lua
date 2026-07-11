function ParseAction(id, original, modified, injected, blocked)
	local ActionPacket = WINDOWER_PACKETS.parse('incoming', original)
	local ActionSource = ActionPacket["Actor"]
	local ActionCategory = ActionPacket["Category"]

	-- The action was made by the player and it is a melee attack
	if ActionSource == GetPlayerID() and ActionCategory == 1 then
		RecordAttackData(ActionPacket)

		local TargetID = GetTargetOverride() or ActionPacket["Target 1 ID"]
		TrimAttackLog(TargetID)
		UpdateChart(TargetID)

	-- The action was made by the current pet and it is a melee attack
	elseif ActionSource == GetPetID() and ActionCategory == 1 then
		print("pet attack")
		--RecordAttackData(ActionPacket)

		--local TargetID = GetTargetOverride() or ActionPacket["Target 1 ID"]
		--TrimAttackLog(TargetID)
		--UpdateChart(TargetID)

	-- The action was made by the player and it is a completed weapon skill
	elseif ActionSource == GetPlayerID() and ActionCategory == 3 then
		RecordWSData(ActionPacket)

		local TargetID = GetTargetOverride() or ActionPacket["Target 1 ID"]
		TrimWSLog(TargetID)
		UpdateChart(TargetID)
	end
end
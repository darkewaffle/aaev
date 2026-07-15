function ParseNPCUpdate(id, original, modified, injected, blocked)
	local NPCUpdatePacket = WINDOWER_PACKETS.parse('incoming', original)
	local NPCID = NPCUpdatePacket["NPC"]

	local NPCStatus = NPCUpdatePacket["Status"]
	local NPCIsDead = NPCStatus >= 2

	local NPCMaskBools = { original:unpack("q8", 11) }
	local NPCStatusChanged = NPCMaskBools[3]
	local NPCTerminated = NPCMaskBools[6]

	local NPCDied = NPCIsDead and NPCStatusChanged

	if (NPCDied or NPCTerminated) and not DeadIDs[NPCID] then

		DeadIDs[NPCID] = true

		if not LogResetPending then
			LogResetPending = true
			coroutine.schedule(ResetAttackData, 20)
		end

		if NPCID == GetPetEnemyTarget() then
			if AutoHide then
				DisplayPetChart(false)
			end
			SetPetEnemyTarget(0)
		end
	end
end
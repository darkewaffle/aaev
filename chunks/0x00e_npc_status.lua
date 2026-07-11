function ParseNPCUpdate(id, original, modified, injected, blocked)
	local NPCUpdatePacket = WINDOWER_PACKETS.parse('incoming', original)
	local NPCMask = IntToBinary(NPCUpdatePacket["Mask"])
	local NPCStatus = NPCUpdatePacket["Status"]

	-- NPC status is dead and the mask indicates this is an actual update
	-- IntToBinary translates right-to-left, so for instance 7 is translated to 00000111
	-- So the sixth character in the string indicates an HP or Status change
	if (NPCStatus == 2 or NPCStatus == 3) and NPCMask[6] == "1" then

		local NPCID = NPCUpdatePacket["NPC"]
		local NPCMob = windower.ffxi.get_mob_by_id(NPCID)
		local NPCSpawnType = 0

		if NPCMob then
			NPCSpawnType = NPCMob["spawn_type"]
		end

		-- spawn_type 16 appears to indicate enemy mobs (as opposed to pets, trusts, friendlies, etc)
		if NPCSpawnType == 16 and not DeadIDs[NPCID] then
			DeadIDs[NPCID] = true
			if not LogResetPending then
				LogResetPending = true
				coroutine.schedule(ResetAttackData, 20)
			end
		end
	end
end
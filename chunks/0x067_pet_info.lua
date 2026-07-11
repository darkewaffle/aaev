function ParsePetInfo(id, original, modified, injected, blocked)
	local PetInfoPacket = WINDOWER_PACKETS.parse('incoming', original)

	local OwnerIndex = PetInfoPacket["Owner Index"]
	local PetID = PetInfoPacket["Pet ID"]
	local PetIndex = PetInfoPacket["Pet Index"]

	if OwnerIndex > 0 and OwnerIndex == GetPlayerIndex() then
		SetPetID(PetID)
		SetPetIndex(PetIndex)

	-- This result seems to indicate that the pet is no longer present
	elseif PetID == GetPlayerID() then
		-- Reset PetID and PetIndex?
	end
end
local HidePetChartTriggers =
{
	[29] = "Spirit Surge",
	[70] = "Heel",
	[71] = "Leave",
	[87] = "Dismiss",
	[89] = "Retreat",
	[90] = "Release",
	[139] = "Deactivate",
	[140] = "Retrieve"
}

function ParseAction(id, original, modified, injected, blocked)

	local ActionSource = original:unpack("b32", 6)

	if ActionSource == GetPlayerID() or ActionSource == GetPetID()then
		local ActionPacket = WINDOWER_PACKETS.parse('incoming', original)
		local ActionCategory = ActionPacket["Category"]
		local ActionID = ActionPacket["Param"]
		local TargetID = GetTargetOverride() or ActionPacket["Target 1 ID"]

		-- Player melee attack
		if ActionSource == GetPlayerID() and ActionCategory == 1 then
			RecordPlayerAttack(ActionPacket)
			TrimPlayerAttackLog(TargetID)
			UpdatePlayerChart(TargetID)

		-- Pet melee attack
		elseif ActionSource == GetPetID() and ActionCategory == 1 then
			RecordPetAttack(ActionPacket)
			TrimPetAttackLog(TargetID)
			UpdatePetChart(TargetID)
			SetPetEnemyTarget(TargetID)

		-- Player weapon skill
		elseif ActionSource == GetPlayerID() and ActionCategory == 3 then
			RecordPlayerWS(ActionPacket)
			TrimPlayerWSLog(TargetID)
			UpdatePlayerChart(TargetID)

		-- Pet ability targeting a monster
		elseif ActionSource == GetPetID() and windower.ffxi.get_mob_by_id(TargetID).spawn_type == 16 then
			local ValidAbility = false

			-- BST Ready
			if ActionCategory == 11 and GetPlayerJob() == 9 then
				RecordPetWS(ActionPacket)
				ValidAbility = true


			-- Automaton TP ability that is configured to be visible
			elseif ActionCategory == 11 and GetPlayerJob() == 18 and MAP_AUTOMATON_WHITELIST[ActionID].display then
				RecordPetWS(ActionPacket)
				ValidAbility = true

			-- Avatar bloodpact or Wyvern breath
			elseif ActionCategory == 13 then
				RecordAvatarWS(ActionPacket)
				ValidAbility = true
			end

			if ValidAbility then
				TrimPetWSLog(TargetID)
				UpdatePetChart(TargetID)
				SetPetEnemyTarget(TargetID)
			end

		-- Job abilities used by the player that trigger hiding the pet chart
		elseif ActionSource == GetPlayerID() and ActionCategory == 6 then
			if HidePetChartTriggers[ActionID] and AutoHide then
				DisplayPetChart(false)
			end
		end
	end
end
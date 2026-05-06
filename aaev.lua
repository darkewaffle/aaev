_addon.name = "AAEV"
_addon.version = "1.0.0"
_addon.author = "darkwaffle"
_addon.command = "AAEV"

require "libraries/colors"
playersettings = require "aaev_settings"

require "libraries/recording"
require "libraries/chart"
require "libraries/background"
require "libraries/bars"
require "libraries/labels"

require "libraries/int_to_binary"
require "libraries/clamp"
require "libraries/modify_strings"
require "libraries/skillchain_messages"

texts = require "texts"
packets = require "packets"
WINDOWER_RESOURCES = require "resources"


local PlayerID = 0
local RegisteredEventIDs = {}

local AutoDemo = playersettings.AutoDemo
if AutoDemo == nil then
	AutoDemo = false
end

local AutoHide = playersettings.AutoHide
if AutoHide == nil then
	AutoHide = true
end

function OnLoad()
	table.insert(RegisteredEventIDs, windower.register_event('login', OnLogin))
	table.insert(RegisteredEventIDs, windower.register_event('unload', OnUnload))
	table.insert(RegisteredEventIDs, windower.register_event('incoming chunk', OnChunk))
	--table.insert(RegisteredEventIDs, windower.register_event('zone change', OnZone))
	table.insert(RegisteredEventIDs, windower.register_event('status change', OnStatusChange))
	table.insert(RegisteredEventIDs, windower.register_event('addon command', OnCommand))

	GetPlayerID()
	CreateChart(false)

	if AutoDemo then
		DemoChart()
	end
end

function OnLogin()
	GetPlayerID()
end

function GetPlayerID()
	local PlayerData = windower.ffxi.get_player()
	if PlayerData then
		PlayerID = PlayerData["id"]
	end
end

function OnUnload()
	for _, ID in ipairs(RegisteredEventIDs) do
		windower.unregister_event(ID)
	end
end

function OnChunk(id, original, modified, injected, blocked)
	-- Action packet that notifies the client of an actor doing something
	if id == 0x028 then

		local ActionPacket = packets.parse('incoming', original)
		local ActionSource = ActionPacket["Actor"]
		local ActionCategory = ActionPacket["Category"]

		-- The action was made by the player and it is a melee attack
		if ActionSource == PlayerID and ActionCategory == 1 then
			RecordAttackData(ActionPacket)

			local TargetID = TargetOverride or ActionPacket["Target 1 ID"]
			TrimAttackLog(TargetID)
			UpdateChart(TargetID)

		-- The action was made by the player and it is a completed weapon skill
		elseif ActionSource == PlayerID and ActionCategory == 3 then
			RecordWSData(ActionPacket)

			local TargetID = TargetOverride or ActionPacket["Target 1 ID"]
			TrimWSLog(TargetID)
			UpdateChart(TargetID)
		end

	-- NPC status update
	-- If DisplayContinuous is enabled then it is not necessary to identify deaths and reset target logs as all data exists in a single log
	elseif id == 0x00E and not DisplayContinuous then

		local NPCUpdatePacket = packets.parse('incoming', original)
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
	
	-- 0x00B indicates a zone change is beginning
	elseif id == 0x00B then
		OnZone()
	end
end

function OnZone()
	ResetAttackLog()
	DisplayChart(false)
end

function OnStatusChange(new_status_id, old_status_id)
	-- New status is engaged
	if new_status_id == 1 then
		local CurrentTarget = windower.ffxi.get_mob_by_target("t")
		if CurrentTarget then
			local TargetID = TargetOverride or CurrentTarget["id"]
			TrimAttackLog(TargetID)
			UpdateChart(TargetID)
		end
	else
		if AutoHide then
			DisplayChart(false)
		end
	end
end

function OnCommand(...)
	local CommandParameters = {...}

	if CommandParameters[1] == "show" then
		DisplayChart(true)
	end

	if CommandParameters[1] == "hide" then
		DisplayChart(false)
	end

	if CommandParameters[1] == "simple" then
		DisplayMode = "simple"
	end

	if CommandParameters[1] == "full" then
		DisplayMode = "full"
	end

	if CommandParameters[1] == "demo" then
		DemoChart()
	end

	if CommandParameters[1] == "help" then
		ChatHelp()
	end

--[[
	if CommandParameters[1] == "print" then
		for k, v in pairs(AttackLog) do
			print(k)
			if type(v) == "table" then
				for k2, v2 in ipairs(v) do
					print(k2 .. ": " .. v2[ATTACK_RESULT] .. " || " .. v2[ATTACK_DAMAGE] .. " || " .. v2[AE_RESULT] .. " || " .. v2[AE_DAMAGE])
				end
			end
		end
	end

	if CommandParameters[1] == "stats" then
		for k, v in pairs(AttackLog) do
			for k2, v2 in pairs(v) do
				if type(v2) ~= "table" then
					print(k2)
					print(v2)
				end
			end
		end
	end
]]

end

function ChatHelp()
	local HelpContents =
	{
		" - - - - - ",
		"Most settings for AAEV are controlled in the 'aaev_settings.lua' file.",
		"AAEV supports the following commands to control it while in game.",
		"      show - forces the chart to display",
		"      hide - forces the chart to hide",
		"      simple - changes the display mode to 'simple'",
		"      full - changes the display mode to 'full'",
		"      demo - displays the chart using a sample dataset",
		" - - - - - "
	}

	for _, Message in ipairs(HelpContents) do
		windower.add_to_chat(1, Message)
	end

end

OnLoad()
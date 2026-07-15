_addon.name = "AAEV"
_addon.version = "1.1.1"
_addon.author = "darkwaffle"
_addon.command = "AAEV"

require "libraries/colors"
playersettings = require "aaev_settings"

require "chunks/aaev_chunks"

require "libraries/recording"
require "libraries/chart"
require "libraries/background"
require "libraries/bars"
require "libraries/labels"

require "libraries/automaton_whitelist"
require "libraries/bloodpact_messages"
require "libraries/clamp"
require "libraries/modify_strings"
require "libraries/skillchain_messages"
require "libraries/weaponskill_messages"

WINDOWER_PACKETS = require "packets"
WINDOWER_RESOURCES = require "resources"
WINDOWER_TEXTS = require "texts"
require "pack"

local PlayerID = 0
local PlayerIndex = 0
local PetID = 0
local PetEnemyTarget = 0
local PlayerMainJob = 0
local IsPetJob = false
local RegisteredEventIDs = {}

local AutoDemo = playersettings.AutoDemo
if AutoDemo == nil then
	AutoDemo = false
end

AutoHide = playersettings.AutoHide
if AutoHide == nil then
	AutoHide = true
end

EnablePetChart = playersettings.PetChart
if EnablePetChart == nil then
	EnablePetChart = false
end

function OnLoad()
	table.insert(RegisteredEventIDs, windower.register_event('login', OnLogin))
	table.insert(RegisteredEventIDs, windower.register_event('unload', OnUnload))
	table.insert(RegisteredEventIDs, windower.register_event('job change', OnJobChange))
	table.insert(RegisteredEventIDs, windower.register_event('zone change', OnZoneEntrance))
	table.insert(RegisteredEventIDs, windower.register_event('status change', OnStatusChange))
	table.insert(RegisteredEventIDs, windower.register_event('incoming chunk', OnChunk))

	table.insert(RegisteredEventIDs, windower.register_event('addon command', OnCommand))

	SetPlayerID()
	SetPlayerJob()
	SetPetID()

	CreatePlayerChart(false)
	CreatePetChart(false)

	if AutoDemo then
		DemoChart()
	end
end

function OnLogin()
	SetPlayerID()
	SetPlayerJob()
end

function OnUnload()
	for _, ID in ipairs(RegisteredEventIDs) do
		windower.unregister_event(ID)
	end
end

function OnJobChange(main_job_id, main_job_level, sub_job_id, sub_job_level)
	if main_job_id == GetPlayerJob() then
		-- Triggered by subjob change, do nothing.
	else
		-- Main job has changed.
		SetPlayerJob(main_job_id)

		if EnablePetChart and GetIsPetJob() then
			CreatePetChart()
		else
			DestroyPetChart()
		end
	end
end

function OnZoneEntrance()
	SetPetID()
end

function OnStatusChange(new_status_id, old_status_id)
	-- New status is engaged
	if new_status_id == 1 then
		local CurrentTarget = windower.ffxi.get_mob_by_target("t")
		if CurrentTarget then
			local TargetID = GetTargetOverride() or CurrentTarget["id"]
			TrimPlayerAttackLog()
			UpdatePlayerChart(TargetID)
		end
	else
		if AutoHide then
			DisplayPlayerChart(false)
		end
	end
end

function OnChunk(id, original, modified, injected, blocked)
	-- Action packet that notifies the client of an actor doing something
	if id == 0x028 then
		ParseAction(id, original, modified, injected, blocked)

	-- NPC status update
	-- If DisplayContinuous is enabled then it is not necessary to identify deaths and reset target logs as all data exists in a single log
	elseif id == 0x00E and not DisplayContinuous then
		ParseNPCUpdate(id, original, modified, injected, blocked)

	elseif id == 0x067 then
		ParsePetInfo(id, original, modified, injected, blocked)
	
	-- 0x00B indicates a zone change is beginning
	elseif id == 0x00B then
		OnZoneExit()
	end
end

function OnZoneExit()
	ResetAttackLogs()
	DisplayCharts(false)
end

function SetPlayerID()
	local PlayerData = windower.ffxi.get_player()
	if PlayerData then
		PlayerID = PlayerData["id"]
	end
end

function GetPlayerID()
	if PlayerID == 0 then
		return nil
	else
		return PlayerID
	end
end

function SetPlayerJob(JobID)
	if JobID and JobID > 0 then
		PlayerMainJob = JobID
	else
		local PlayerData = windower.ffxi.get_player()
		if PlayerData then
			PlayerMainJob = PlayerData.main_job_id
		end
	end

	if (PlayerMainJob == 9 or PlayerMainJob == 14 or PlayerMainJob == 15 or PlayerMainJob == 18) then
		SetIsPetJob(true)
	else
		SetIsPetJob(false)
	end
end

function GetPlayerJob()
	if PlayerMainJob == 0 then
		return nil
	else
		return PlayerMainJob
	end
end

function SetIsPetJob(State)
	IsPetJob = State
end

function GetIsPetJob()
	return IsPetJob
end

function SetPetID(NewPetID)
	local GetPet = windower.ffxi.get_mob_by_target("pet")
	if GetPet then
		PetID = GetPet.id
	else
		PetID = 0
	end
end

function GetPetID()
	if PetID == 0 then
		return nil
	else
		return PetID
	end
end

function SetPetEnemyTarget(TargetID)
	if not DeadIDs[TargetID] then
		PetEnemyTarget = TargetID
	end
end

function GetPetEnemyTarget()
	if PetEnemyTarget ~= 0 then
		return PetEnemyTarget
	else
		return nil
	end
end

function OnCommand(...)
	local CommandParameters = {...}

	if CommandParameters[1] == "show" then
		DisplayCharts(true)
	end

	if CommandParameters[1] == "hide" then
		DisplayCharts(false)
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
	if CommandParameters[1] == "petlog" then
		local PetLog = GetPetAttackLog()
		for k, v in pairs(PetLog) do
			print(k)
			if type(v) == "table" then
				for k2, v2 in ipairs(v) do
					print(k2 .. ": " .. v2[ATTACK_RESULT] .. " || " .. v2[ATTACK_DAMAGE] .. " || " .. v2[AE_RESULT] .. " || " .. v2[AE_DAMAGE])
				end
			end
		end
	end

	if CommandParameters[1] == "petws" then
		print(GetPetID())
		local PetLog = GetPetAttackLog()
		for k, v in pairs(PetLog) do
			print(k)
			--if type(v) == "table" then
				if v[WEAPON_SKILL_LOG] then
					print("ws log found")
				end

				for k2, v2 in ipairs(v[WEAPON_SKILL_LOG]) do
					print(k2 .. ": " .. v2[WS_NAME] .. " || " .. v2[WS_DAMAGE] .. " || " .. tostring(v2[WS_RESULT]) .. " || " .. tostring(v2[SC_NAME]) .. " || " .. tostring(v2[SC_DAMAGE]) .. " || " .. tostring(v2[SC_RESULT]))
				end
			--end
		end
	end

	if CommandParameters[1] == "playerlog" then
		for k, v in pairs(AttackLog) do
			print(k)
			if type(v) == "table" then
				for k2, v2 in ipairs(v) do
					print(k2 .. ": " .. v2[ATTACK_RESULT] .. " || " .. v2[ATTACK_DAMAGE] .. " || " .. v2[AE_RESULT] .. " || " .. v2[AE_DAMAGE])
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
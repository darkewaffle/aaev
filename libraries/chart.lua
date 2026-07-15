DisplayMode = playersettings.DisplayMode or "full"

ChartBars = playersettings.ChartBars or 25
ChartStartX = playersettings.ChartStartX or 500
ChartStartY = playersettings.ChartStartY or 500
ChartWidth = playersettings.ChartWidth or 100
ChartHeight = playersettings.ChartHeight or 30

PetChartBars = playersettings.PetChartBars or 20
PetChartStartX = playersettings.PetChartStartX or 500
PetChartStartY = playersettings.PetChartStartY or 800
PetChartWidth = playersettings.PetChartWidth or 100
PetChartHeight = playersettings.PetChartHeight or 43

local PetChartCreated = false

function CreatePlayerChart(Visible)
	CreatePlayerBackground(Visible)
	CreatePlayerBars(Visible)
	CreatePlayerLabels(Visible)
end

function CreatePetChart(Visible)
	if EnablePetChart and GetIsPetJob() and not PetChartCreated then
		CreatePetBackground(Visible)
		CreatePetBars(Visible)
		CreatePetLabels(Visible)
		PetChartCreated = true
	end
end

function DisplayCharts(Visible)
	DisplayPlayerChart(Visible)
	DisplayPetChart(Visible)
end

function DisplayPlayerChart(Visible)
	DisplayPlayerBackground(Visible)
	DisplayPlayerBars(Visible)
	DisplayPlayerLabels(Visible)
end

function DisplayPetChart(Visible)
	if EnablePetChart and GetIsPetJob() and PetChartCreated then
		DisplayPetBackground(Visible)
		DisplayPetBars(Visible)
		DisplayPetLabels(Visible)
	end
end

function UpdatePlayerChart(TargetID)
	local PlayerAttackLog = GetPlayerAttackLog()
	if PlayerAttackLog[TargetID] and (#PlayerAttackLog[TargetID] > 0 or #PlayerAttackLog[TargetID][WEAPON_SKILL_LOG] > 0) then
		DisplayPlayerBackground(true)
		UpdatePlayerBars(TargetID)
		UpdatePlayerLabels(TargetID)
	else
		DisplayPlayerChart(false)
	end
end

function UpdatePetChart(TargetID)
	if EnablePetChart and GetIsPetJob() and PetChartCreated then
		local PetAttackLog = GetPetAttackLog()

		if not DeadIDs[TargetID] then
			if PetAttackLog[TargetID] and (#PetAttackLog[TargetID] > 0 or #PetAttackLog[TargetID][WEAPON_SKILL_LOG] > 0) then
				DisplayPetBackground(true)
				UpdatePetBars(TargetID)
				UpdatePetLabels(TargetID)
			else
				DisplayPetChart(false)
			end
		end
	end
end

function DestroyPetChart()
	if EnablePetChart and PetChartCreated then
		DestroyPetBackground()
		DestroyPetBars()
		DestroyPetLabels()
		PetChartCreated = false
	end
end

function DemoChart()
	CreateDemoLogs()
	TrimPlayerWSLog(1)
	UpdatePlayerChart(1)
	TrimPetWSLog(1)
	UpdatePetChart(1)
end
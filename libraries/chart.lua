DisplayMode = playersettings.DisplayMode or "full"

ChartBars = playersettings.ChartBars or 25
ChartStartX = playersettings.ChartStartX or 500
ChartStartY = playersettings.ChartStartY or 500
ChartWidth = playersettings.ChartWidth or 100
ChartHeight = playersettings.ChartHeight or 30

function CreateChart(Visible)
	CreateBars(Visible)
	CreateLabels(Visible)
end

function DisplayChart(Visible)
	DisplayBars(Visible)
	DisplayLabels(Visible)
end

function UpdateChart(TargetID)
	if AttackLog[TargetID] then
		UpdateBars(TargetID)
		UpdateLabels(TargetID)
	end
end
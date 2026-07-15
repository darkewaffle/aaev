local settings = {}

	-- "full" or "simple"
	settings.DisplayMode = "full"

	-- Causes the data to not be tracked per target but rather across all targets, the chart will not be reset when attacking a new target.
	settings.DisplayContinuous = false

	-- When true then any additional effect damage will be added to the base hit damage for the purposes of determining Max damage dealt and size of the bar
	-- Each hit will be represented as a single bar
	settings.AdditionalEffectSingleBar = false

	-- When true then additional effect damage will be displayed as a second bar stacked on top of the bar for the physical damage hit
	-- Each hit that includes an additional effect that deals damage will be displayed as two bars stacked together
	-- Note that this also effectively doubles the number of bars that the chart is tracking - if you experience performance issues then turning this off or reducing the number of ChartBars may help.
	-- AdditionalEffectSingleBar and AdditionalEffectStackBars should not be used together. If they are both true then only AdditionalEffectSingleBar will take effect.
	settings.AdditionalEffectStackBars = true

	-- When true the chart will be automatically hidden when you are no longer engaged and attacking an enemy.
	-- When false the chart will remain visible when you disengage. It will still be hidden when changing zones.
	settings.AutoHide = true

	-- When true the demo dataset and chart will be automatically displayed when the addon is loaded
	-- Useful to quickly see the results of adjusting your settings and reload to iterate
	settings.AutoDemo = false


	-- Maximum number of bars (attacks) that the chart will display
	-- Recommended to not set this super high as each bar, even if not visible, will be evaluated in every update
	settings.ChartBars = 20
	-- Starting horizontal position of the chart. 0 is the left side of the screen, positive values move it to the right. Range depends on resolution.
	settings.ChartStartX = 500
	-- Starting vertical position of the chart. 0 is the top of the screen, positive values move it down. Range depends on resolution.
	settings.ChartStartY = 500
	settings.ChartWidth = 100
	settings.ChartHeight = 43


	-- Transparency for the chart bars
	-- 0 is completely transparent (not visible), 255 is completely opaque
	settings.BarsAlpha = 255
	-- Can set to colors found in "colors.lua" or defined as {r, g, b} values
	-- eg: ColorHit = {255, 0, 255} to make ColorHit = purple
	settings.ColorHit = Blue
	settings.ColorCrit = BluePale
	settings.ColorMiss = White
	settings.ColorBlock = Grey3
	settings.ColorHitZero = Grey2
	settings.ColorCounter = Red
	settings.ColorHeal = GreenLime
	settings.ColorAdditionalEffect = Grey1
	settings.ColorAdditionalEffectHeal = GreenLime


	-- Controls the display of a background for the chart
	settings.BGDisplay = true
	-- Controls the background color
	settings.BGColor = Black
	-- Controls the space between the bounds of the chart data and the edge of the background
	settings.BGPaddingX = 5
	settings.BGPaddingY = 25
	-- Controls the position of the background relative to the chart.
	-- BGOffsetX <0 moves it left, >0 moves it right.
	-- BGOffsetY <0 moves it down, >0 moves it up.
	settings.BGOffsetX = 0
	settings.BGOffsetY = 0
	-- Transparency for the backcround
	-- 0 is completely transparent (not visible), 255 is completely opaque
	settings.BGAlpha = 128


	-- Controls the display of the max damage text Label
	settings.DisplayMax = true
	settings.MaxLabelPrefix = "Max: "
	-- Controls the display of the hit rate text Label
	settings.DisplayHitRate = true
	settings.HitRateLabelPrefix = "Hit: "
	-- Controls the font used for Labels
	settings.LabelFont = 'Consolas'
	settings.LabelSize = 11
	settings.LabelAlpha = 255
	settings.LabelColor = White
	-- Controls the highlight/outline of the Label font
	settings.LabelHighlightColor = Black
	settings.LabelHighlightAlpha = 128
	settings.LabelHighlightThickness = 1
	-- Controls the number of pixels between the Chart and the Labels
	settings.LabelOffsetUp = 21
	settings.LabelOffsetDown = 3
	settings.LabelOffsetRight = 2


	-- Controls the display of Weaponskill results
	settings.DisplayWeaponskills = true
	-- Controls whether they are displayed top to bottom or bottom to top
	settings.ReverseWeaponskills = false
	-- Total number of weaponskill results that are retained and displayed
	settings.WeaponskillCount = 5
	-- Sets the exact position of the weaponskill results
	-- If these are not defined then they will be automatically placed next to the top right corner of the chart
	--settings.WeaponskillX = 650
	--settings.WeaponskillY = 500


	settings.PetChart = true
	settings.PetChartBars = 20
	settings.PetChartStartX = 500
	settings.PetChartStartY = 650
	settings.PetChartWidth = 100
	settings.PetChartHeight = 43
	settings.PetWeaponskillCount = 5
	--settings.PetWeaponskillX = 600
	--settings.PetWeaponskillY = 600

return settings
local settings = {}

	-- "full" or "simple"
	settings.DisplayMode = "full"

	-- Maximum number of bars (attacks) that the chart will display
	-- Recommended to not set this super high as each bar, even if not visible, will be evaluated in every update
	settings.ChartBars = 20

	-- Starting horizontal position of the chart. 0 is the left side of the screen, positive values move it to the right. Range depends on resolution.
	settings.ChartStartX = 500
	-- Starting vertical position of the chart. 0 is the top of the screen, positive values move it down. Range depends on resolution.
	settings.ChartStartY = 500

	settings.ChartWidth = 100
	settings.ChartHeight = 30

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

	-- Controls the display of the max damage text value
	settings.DisplayMax = true
	-- Controls the display of the hit rate text value
	settings.DisplayHitRate = true

	-- Controls the display of a background for the chart
	settings.BGDisplay = true
	-- Controls the background color
	settings.BGColor = Black
	-- Controls the space between the bounds of the chart data and the edge of the background
	settings.BGPadding = 3
	-- Transparency for the backcround
	-- 0 is completely transparent (not visible), 255 is completely opaque
	settings.BGAlpha = 128

return settings
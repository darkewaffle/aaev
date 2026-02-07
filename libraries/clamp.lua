function Clamp(Input, MinValue, MaxValue)
	local ClampedValue = Input
	ClampedValue = math.min(ClampedValue, MaxValue)
	ClampedValue = math.max(ClampedValue, MinValue)
	return ClampedValue
end
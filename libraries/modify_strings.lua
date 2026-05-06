function SetStringWidth(StringInput, ToWidth, PadCharacter, PadLeft)
	local Padding = PadCharacter or " "
	local StringOutput = ""
	local StringInput = tostring(StringInput)

	if #StringInput < ToWidth then
		if PadLeft then
			StringOutput = string.rep(Padding, ToWidth - #StringInput) .. StringInput
		else
			StringOutput = StringInput .. string.rep(Padding, ToWidth - #StringInput)
		end
	else
		StringOutput = string.sub(StringInput, 1, ToWidth)
	end

	return StringOutput
end

function ColorWrapForTexts(StringToWrap, Red, Green, Blue)
	Red = Red or 255
	Green = Green or 255
	Blue = Blue or 255

	local ColorPrefix = "\\cs(" .. Red .. "," .. Green .. "," .. Blue .. ")"
	local ColorSuffix = "\\cr"
	return ColorPrefix .. StringToWrap .. ColorSuffix
end

function CapitalizeFirstLetter(InputString)
	local FirstLetter = string.upper(string.sub(InputString, 1, 1))
	local RestOfTheWord = string.sub(InputString, 2, #InputString)
	return FirstLetter .. RestOfTheWord
end
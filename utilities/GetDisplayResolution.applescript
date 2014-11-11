-- properties persist across sessions in compiled .scpt files
-- so subsequent runs will be faster
property pX : missing value
property pY : missing value


on run {}
	displayResoln()
end run

on displayResoln()
	if (pX is missing value) or (pY is missing value) then
		set {dlm, my text item delimiters} to {my text item delimiters, "Resolution"}
		set lstDisplays to text items of (do shell script "system_profiler SPDisplaysDataType")
		
		repeat with i from 2 to length of lstDisplays
			set strLine to item i of lstDisplays
			if strLine contains "Main Display: Yes" then exit repeat
		end repeat
		set my text item delimiters to space
		set lstParts to text items of strLine
		set my text item delimiters to dlm
		set {strX, strY} to {item 2, item 4} of lstParts
		set {pX, pY} to {strX as integer, strY as integer}
	end if
	return {pX , pY}
end displayResoln
property pTitle : "Register and handle ftdoc:// url scheme"property pVer : "0.02"property pAuthor : "Rob Trew"property pDescription : "

	Use in conjunction with the 'FTCopyAsURL' Applescript to get
	a URL which opens the specified document, optionally restoring selection and filter state.

"-- Registers the url-scheme ftdoc://encoded-file-path[?nodepath=//@due][?line=N][?startoffset=0][?endoffset=-1]-- where line is zero-based and defaults to 0-- startoffset is an offset of a number of characters from the start of the line-- endoffset is ditto-- and the url opens the document in FoldingText:-- 1. Applying any specified path-- 2. Selecting any specified line (unfolding if necessary to unhide the line)-- 3. Restricts the selection to a subset of the line if startoffset > 0 or endoffset ≠ -1-- for the approach to registering and handling a url with an applescript.app and the .plist in its bundle,-- see http://www.macosxautomation.com/applescript/linktrigger/property piNodePath : 1property piLine : 2property piStartOffset : 3property piEndOffset : 4property plstKeys : {"nodepath", "line", "startoffset", "endoffset"}property plngKeys : length of plstKeysproperty pstrJS : "
	// given the switches from a url, and the document opened by that url,
	// set a nodepath, and/or select (all or part of) a line indicated by the url switches
	//eg    ftdoc:///Users/robintrew/Library/Application%20Support/Notational%20Velocity/project%20work.txt?line=3?startoffset=5?endoffset=10?nodepath=//@due

	function(editor, options) {
		var	tree=editor.tree(),
			oNode, rngSeln,
			strPath = options.nodepath, strLine=options.line,
			strStartOffset=options.startoffset, strEndOffset=options.endoffset,
			lngLine, lngStartOffset=0, lngEndOffset=-1, varStartOffset, varEndOffset;

		if (strPath !== null) {
			editor.setNodePath(strPath);
		}
		if (strLine !== null) {
			lngLine = parseInt(strLine, 10);
			if (lngLine !== NaN) {
				oNode = tree.lineNumberToNode(lngLine);
				if (editor.nodeIsHiddenInFold(oNode)) {
					editor.expandToRevealNode(oNode);
					editor.scrollToLine(lngLine);
				}
				if (strStartOffset !== null) {
					varStartOffset = parseInt(strStartOffset, 10);
					if (varStartOffset !== NaN) lngStartOffset = varStartOffset
				}
				if (strEndOffset !== null) {
					varEndOffset = parseInt(strEndOffset, 10);
					if (varEndOffset !== NaN) lngEndOffset = varEndOffset
				}
				rngSeln = tree.createRangeFromNodes(oNode, lngStartOffset, oNode, lngEndOffset);
				editor.setSelectedRange(rngSeln);
			}
		}
	}
"on open location strURL	--	set recParse to parseURL("ftdoc:///Users/robintrew/Library/Application%20Support/Notational%20Velocity/project%20work.txt?line=3?startoffset=5?endoffset=10?nodepath=//@due")	set recParse to parseURL(urldecode(strURL))		tell application "FoldingText"		activate		set oDoc to open (filepath of recParse)		tell oDoc to set varResult to (evaluate script pstrJS with options (switches of recParse))	end tellend open location-- "ftdoc://encoded-file-path[?nodepath=//@due][?line=N][?startoffset=0][?endoffset=-1]"on parseURL(strURL)	-- length, line, nodepath, offset	set lstSwitches to {}	repeat with i from 1 to plngKeys		set end of lstSwitches to null	end repeat		set {dlm, my text item delimiters} to {my text item delimiters, "ftdoc://"}	set lstParts to text items of strURL	if length of lstParts > 1 then		set strTarget to item 2 of lstParts		set my text item delimiters to "?"		set lstParts to text items of strTarget		set strFile to item 1 of lstParts		set lngParts to length of lstParts		if lngParts > 1 then			set my text item delimiters to "="						repeat with i from 2 to lngParts				set lstKeyValue to text items of (item i of lstParts)				if length of lstKeyValue > 1 then					set strKey to item 1 of lstKeyValue					if plstKeys contains strKey then						repeat with i from 1 to plngKeys							if strKey = item i of plstKeys then								set item i of lstSwitches to (items 2 thru -1 of lstKeyValue) as string								exit repeat							end if						end repeat					end if				end if			end repeat		end if	end if	set my text item delimiters to dlm	set recSwitches to {nodepath:item piNodePath of lstSwitches, |line|:item piLine of lstSwitches, startoffset:item piStartOffset of lstSwitches, endoffset:item piEndOffset of lstSwitches}	return {filepath:strFile, switches:recSwitches}end parseURL-- EITHER do shell script "php -r 'echo urldecode(\"" & filepath of recParse & "\");'"-- OR (this is faster):on urldecode(theText) -- http://harvey.nu/applescript_url_decode_routine.html	set sDst to ""	set sHex to "0123456789ABCDEF"	set i to 1	repeat while i ≤ length of theText		set c to character i of theText		if c = "+" then			set sDst to sDst & " "		else if c = "%" then			if i > ((length of theText) - 2) then				display dialog ("Invalid URL Encoded string - missing hex char") buttons {"Crap..."} with icon stop				return ""			end if			set iCVal1 to (offset of (character (i + 1) of theText) in sHex) - 1			set iCVal2 to (offset of (character (i + 2) of theText) in sHex) - 1			if iCVal1 = -1 or iCVal2 = -1 then				display dialog ("Invalid URL Encoded string - not 2 hex chars after % sign") buttons {"Crap..."} with icon stop				return ""			end if			set sDst to sDst & (ASCII character (iCVal1 * 16 + iCVal2))			set i to i + 2		else			set sDst to sDst & c		end if		set i to i + 1	end repeat	return sDstend urldecode
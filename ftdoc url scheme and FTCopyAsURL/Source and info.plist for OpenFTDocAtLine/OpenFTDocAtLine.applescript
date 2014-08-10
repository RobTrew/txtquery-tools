property pTitle : "Register and handle ftdoc:// url scheme"property pVer : "0.04"property pAuthor : "Rob Trew"property pDescription : "

	Use in conjunction with the 'FTCopyAsURL' Applescript to get
	a URL which opens the specified document, optionally restoring selection and filter state.

"-- Registers the url-scheme ftdoc://encoded-file-path with optional switches:--[?nodepath=//@due] -- nodepath used to apply a filter--[?selnpath=] -- nodepath used to specify a selection--[?find=] -- text string to find--[?line=N][?startoffset=0][?endoffset=-1]-- where line is zero-based and defaults to 0-- startoffset is an offset of a number of characters from the start of the line-- endoffset is ditto-- and the url opens the document in FoldingText:-- 1. Applying any specified ?nodepath= value as a filter-- 2. Selecting the first line that matches (in the following order)--	--	the value of ?selnpath= ?find= or ?line=-- 3. Restricts the selection to a subset of a line selected by number if startoffset > 0 or endoffset ≠ -1-- for the approach to registering and handling a url with an applescript.app and the .plist in its bundle,-- see http://www.macosxautomation.com/applescript/linktrigger/property piNodePath : 1property piSelnPath : 2property piFindText : 3property piLine : 4property piStartOffset : 5property piEndOffset : 6property plstKeys : {"nodepath", "selnpath", "find", "line", "startoffset", "endoffset"}property plngKeys : length of plstKeysproperty pjsSelect : "

function(editor, options) {
	function getValue(strSwitch) {
		return lstSwitches[lstSwitches.indexOf('?' + strSwitch + '=')+1];
	}
	
	var	tree= editor.tree(),
		oNode, rngSeln,
		//options.filepath, options.switches, options.keys
		lstKeys = options.keys,
		strRegex = '(\\\\?' + lstKeys.join('=|\\\\?') + '=)',
		oRegex = new RegExp(strRegex, 'g'),
		strPath = decodeURIComponent(options.filepath), 
		strSwitches = decodeURIComponent(options.switches),
		lstSwitches = strSwitches.split(oRegex),
		strPath, strLineNum,
		strSelnPath,
		strFind,
		strStartOffset, strEndOffset,
		lngLine, lngStartOffset=0, lngEndOffset=-1,
		varStartOffset, varEndOffset,
		lstMatches=[], lstRanges=[], i;
		
	
	// Try to restore any selection that is specified
	if (strPath = getValue('nodepath')) {
		//restore any filter
		editor.setNodePath(strPath);
	}
		
	
	strSelnPath = getValue('selnpath');
	strFind = getValue('find');
	
	if (strSelnPath || strFind) {
		if (strSelnPath) {
			lstMatches = tree.evaluateNodePath(strSelnPath);
		}
		if (strFind && (lstMatches.length == 0)) {
			lstMatches = tree.evaluateNodePath('//\"' + strFind + '\"');
		}
		if (lstMatches.length) {
			lstMatches.forEach(function(varNode) {
				lstRanges.push(tree.createRangeFromNodes(
					varNode, 0, varNode, -1));
				// unfold if this range is hidden
				if (editor.nodeIsHiddenInFold(varNode)) {
					editor.expandToRevealNode(varNode);
				}
			});
			editor.setSelectedRanges(lstRanges);
			//Make sure that at least the first of any selections is visible
			editor.scrollRangeToVisible(lstRanges[0]);
		}
	} else {
		
		// make any selection specified by line number etc
		if (strLine = getValue('line')) {
			lngLine = parseInt(strLine, 10);
			if (!(isNaN(lngLine))) {
				oNode = tree.lineNumberToNode(lngLine);
				if (editor.nodeIsHiddenInFold(oNode)) {
					editor.expandToRevealNode(oNode);
					editor.scrollToLine(lngLine);
				}
		
				if (strStartOffset = getValue('startoffset')) {
					varStartOffset = parseInt(strStartOffset, 10);
					if (!isNaN(varStartOffset)) {
						lngStartOffset = varStartOffset;
					}
				}
		
				if (strEndOffset = getValue('endoffset')) {
					varEndOffset = parseInt(strEndOffset, 10);
					if (!isNaN(varEndOffset)) {
						lngEndOffset = varEndOffset;
					}
				}

				rngSeln = tree.createRangeFromNodes(
					oNode, lngStartOffset, oNode, lngEndOffset);
				editor.setSelectedRange(rngSeln);
			}
		}
	}
}
"on open location strURL	set recParse to pathAndSwitches(strURL)	if recParse is not missing value then		set strPath to Decode(filepath of recParse)				tell application "FoldingText"			set oDoc to (open strPath)			tell oDoc				set varResult to (evaluate script pjsSelect with options (recParse & {keys:plstKeys}))				activate			end tell		end tell	end ifend open location--on Decode(strEncodedPath)--	set strCMD to "JSC=/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc--\"$JSC\" -e \"print(decodeURI('" & strEncodedPath & "'));\""--	return do shell script strCMD--end Decodeon Decode(strEncodedPath)	set strCMD to "
urldecode() {
	local url_encoded=\"${1//+/ }\"
	printf '%b' \"${url_encoded//%/\\x}\"
}
urldecode '" & strEncodedPath & "'"	return do shell script strCMDend Decodeon pathAndSwitches(strURL)	-- we can't simply split on '?' as there may be '?' in the text	-- extracting the file in .js would require an active document, 	-- so we do it here to save the time and distraction caused by creating one	set strSwitches to ""	set {dlm, my text item delimiters} to {my text item delimiters, "ftdoc://"}	set lstParts to text items of strURL	if length of lstParts < 2 then		set varParse to missing value	else		set strTarget to item 2 of lstParts		set lngFull to length of strTarget		set lngClosest to lngFull		repeat with varKey in plstKeys			set my text item delimiters to ("?" & varKey & "=")			set lstParts to text items of strTarget			if length of lstParts > 1 then				set lngPosn to length of item 1 of lstParts				if lngPosn < lngClosest then set lngClosest to lngPosn			end if		end repeat		set strPath to text 1 thru lngClosest of strTarget		if lngClosest < lngFull then			set strSwitches to text (lngClosest + 1) thru -1 of strTarget		end if		set varParse to {filepath:strPath, switches:strSwitches}	end if	set my text item delimiters to dlm	return varParseend pathAndSwitches---- "ftdoc://encoded-file-path[?nodepath=//@due][?line=N][?startoffset=0][?endoffset=-1]"
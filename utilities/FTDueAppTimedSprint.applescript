property pTitle : "Current line as timed Due.app sprint @mins(N)"property pVer : "0.2"property pAuthor : "Rob Trew"property plngDefaultMins : 55property pstrDurationTag : "mins"property pDescription : "

	1. Select one or more lines with or without @mins(N) tags
	2. Run the script and confirm the first reminder
	3. Whenever a reminder terminates, tap the **right arrow key** in Due.app to launch the next x-callback
	4. The next timed reminder will start ...
"property pstrJS : "
	function(editor, options) {
	
		// TAIL RECURSION TO NEST SUBSEQUENT REMINDER TEXTS AND TIMES
		// IN FURTHER ENCODED X-CALLBACK URLS
		function nestURL(lstTextMins) {
			var lstHead=lstTextMins[0],
				lstTail=lstTextMins.slice(1),
				strText=lstHead[0], lngMins=lstHead[1],
				strURL, strEncoded, strSpacer = '        ';
		
			strEncoded = encodeURIComponent(strText + strSpacer);
		
			if (lstTail.length) {
				strEncoded += encodeURIComponent(nestURL(lstTail));
			}
		
			strURL = ['due://x-callback-url/add?title=', strEncoded,
					'&minslater=', lngMins.toString()].join('');
			return strURL;
		}

		var lstSelns=editor.selectedRanges(),
			lstNodes, oNode, lngNodes, lstStages=[],
			lngMins=options.defaultmins,
			strTag = options.timetag,
			strText, strURL, i,j;
	
		// ITERATE THROUGH MULTIPLE SELECTIONS OF ONE OR MORE LINES EACH
		lstSelns.forEach(function(rngSeln) {
			lstNodes=rngSeln.nodesInRange();
			lngNodes=lstNodes.length;
			for (i=0; i<lngNodes; i++) {
				oNode=lstNodes[i];
				if (oNode.hasTag(strTag)) {
					lngMins = parseInt(oNode.tag(strTag), 10);
				} else {
					lngMins = plngDefaultMins;
				}
				lstStages.push([oNode.text(), lngMins]);
			}
		});
	
		strURL = nestURL(lstStages);
		editor.openLink(strURL);
		return strURL;
	}
"on run	set strURL to ""	tell application "FoldingText"		set lstDocs to documents		if lstDocs ≠ {} then tell item 1 of lstDocs to set strURL to (evaluate script pstrJS with options {timetag:pstrDurationTag, defaultmins:plngDefaultMins})	end tell	tell application "Due" to activate	set the clipboard to strURL	return strURLend run
property pTitle : "Current line as timed Due.app sprint @mins(N)"property pVer : "0.3"property pAuthor : "Rob Trew"property plngDefaultMins : 55property pstrMinutesTag : "mins" -- eg @mins(30)property pstrPomodoroTag : "pom" -- eg @pom or @pom(2) but see plngMinutesPerPomodoro below-- EXCHANGE RATE: MINUTES PER POMODORO UNIT:-- set plngMinutesPerPomodoro below to 1 if @pom(2) just means two minutes -- but set for example, to 30 if @pom(2) is an hour-- @pom and @pom(1) are interchangeableproperty plngMinutesPerPomodoro : 1 -- OR 25 ETC ?property pDescription : "

	FIRST ADJUST SETTINGS:
	Edit values above for:
	- Default number of minutes if there is no tag (plngDefaultMins, default 55)
	- Tag to use for number of minutes (pstrMinutesTag, default mins, eg @mins(30) )
	- Tag to use for pomodoros (pstrPomodoroTag, default pom, eg @pom, @pom(2), @pom(25))
	- Number of minutes per pomodoro (plngMinutesPerPomodoro, default 1, but might be 25 or more)

	THEN USE:
	1. Select one or more lines with or without @mins(N) tags (discontinuous ⌘-click selections are fine )
	2. Run the script and confirm the first reminder
	3. Whenever a reminder terminates, tap the **right arrow key** in Due.app to launch the next x-callback
	4. The next timed reminder will be initiated.

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
			lngDefaultMins=options.defaultmins,
			strMinsTag = options.timetag,
			strPomTag = options.pomtag,
			lngMinsPerPom = options.pomodoromins,
			lngMins, lngPom, strPom,
			strText, strURL, i,j;

		// ITERATE THROUGH MULTIPLE SELECTIONS OF ONE OR MORE LINES EACH
		lstSelns.forEach(function(rngSeln) {
			lstNodes=rngSeln.nodesInRange();
			lngNodes=lstNodes.length;
			for (i=0; i<lngNodes; i++) {
				lngMins = 0;
				oNode=lstNodes[i];

				if (oNode.hasTag(strMinsTag)) {
					lngMins = parseInt(oNode.tag(strMinsTag), 10);
				} 

				// HANDLE ANY POMODORO TAG - IF A LINE HAS BOTH TAG TYPES, JUST SUM THE MINS
				if (oNode.hasTag(strPomTag)) {
					strPom = oNode.tag(strPomTag);
					if (strPom) {
						lngMins += (parseInt(strPom, 10) * lngMinsPerPom);
					} else {
						lngMins += lngMinsPerPom;
					}
				}

				// FALL BACK TO DEFAULT IF THERE ARE NO TAGS
				if (lngMins < 1) lngMins = lngDefaultMins;
				lstStages.push([oNode.text(), lngMins]);
			}
		});

		strURL = nestURL(lstStages);
		editor.openLink(strURL);
		return strURL;
	}
"on run	set strURL to ""	tell application "FoldingText"		set lstDocs to documents		if lstDocs ≠ {} then			tell item 1 of lstDocs				set strURL to (evaluate script pstrJS with options {defaultmins:plngDefaultMins, pomodoromins:plngMinutesPerPomodoro, timetag:pstrMinutesTag, pomtag:pstrPomodoroTag})			end tell		end if	end tell	tell application "Due" to activate	set the clipboard to strURL	return strURLend run
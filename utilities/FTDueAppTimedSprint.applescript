property pTitle : "Current line as timed Due.app sprint @mins(N)"property pVer : "0.2"property pAuthor : "Rob Trew"property plngDefaultMins : 55property pstrDurationTag : "mins"property pstrJS : "
	function(editor, options) {
		
		var oNode= editor.selectedRange().startNode,
			strText=encodeURIComponent(oNode.text()),
			strTag = options.timetag,
			lngMins=options.defaultmins, strURL;
			
		if (oNode.hasTag(strTag)) lngMins = parseInt(oNode.tag(strTag), 10);
		
		strURL = ['due://x-callback-url/add?title=', strText, '&minslater=', lngMins.toString()].join('');
		editor.openLink(strURL);
		return strURL;
}
"on run	set strURL to ""	tell application "FoldingText"		set lstDocs to documents		if lstDocs ≠ {} then tell item 1 of lstDocs to set strURL to (evaluate script pstrJS with options {timetag:pstrDurationTag, defaultmins:plngDefaultMins})	end tell	tell application "Due" to activate	return strURLend run
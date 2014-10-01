-- ver 1.0.2 toggles visibility of @done without losing any existing focusproperty pstrJS : "

	function(editor) {
		var strActivePath = editor.nodePath().nodePathString,
			lstNodes,
			strExceptDone = ' except //@done',  lngChars=strExceptDone.length,
			strToggledPath, lngStart;

		switch (strActivePath) {
			case '///*':
				strToggledPath = '//not @done';
				break;
			case '//not @done':
				strToggledPath = '///*';
				break;
			default :
				lngStart = strActivePath.length-lngChars;
				if (strActivePath.indexOf(' except //@done', lngStart) == -1)
					strToggledPath = strActivePath + strExceptDone;
				else
					strToggledPath = strActivePath.substring(0, lngStart);
				break;
		}
		editor.setNodePath(strToggledPath);
	}

"tell application "FoldingText"	set lstDocs to documents	if lstDocs ≠ {} then		tell item 1 of lstDocs to (evaluate script pstrJS)	end ifend tell
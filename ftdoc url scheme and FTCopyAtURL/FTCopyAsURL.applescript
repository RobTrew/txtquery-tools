property pTitle : "Copy FT selection as ftdoc:// url"property pVer : "0.01"property pAuthor : "Rob Trew"property pDescription : "

	Copies the selected text in FoldingText as an ftdoc:// URL 
	linking back to the current document, selection, and filter state.
	
	(Uses the ftdoc:// url-scheme - registered and handled by the OpenFTDocAtLine.app applescript app bundle)

"property pstrJS : "

	function(editor, options) {
	
	var	tree=editor.tree(),
		strNodePath = editor.nodePath().toString(),
		rngSeln = editor.selectedRange(),
		dctStartOffset = rngSeln.startLineCh(),
		lngLine = dctStartOffset.line,
		lngStartOffset=dctStartOffset.ch,
		dctEndOffset = rngSeln.endLineCh(),
		lngEndOffset=-1,
		strDocPath=options.docpath, strURL='',
		strEncoded;

		if (dctEndOffset.line = lngLine) {
			lngEndOffset = dctEndOffset.ch;
		}
		strURL='ftdoc://' + strDocPath;

		if (strNodePath !== '///*') {
			strURL = strURL + '?nodepath=' + strNodePath;
		}
		if (lngLine) {
			strURL = strURL + '?line=' + lngLine.toString();
		}
		if (lngStartOffset) {
			strURL = strURL + '?startoffset=' + lngStartOffset.toString();
		}
		if (lngEndOffset > 0) {
			strURL = strURL + '?endoffset=' + lngEndOffset.toString();
		}
		return encodeURI(strURL);
	}

"on run	set varResult to missing value	tell application "FoldingText"		set lstDocs to documents		if lstDocs ≠ {} then			set oDoc to item 1 of lstDocs			tell oDoc				set strPath to POSIX path of ((file of it) as alias)				set strURL to (evaluate script pstrJS with options {docpath:strPath})				tell application "Finder" to set the clipboard to strURL			end tell		end if	end tell	display notification "ftdoc:// url copied for current selection & filter state" & linefeed & strURL	return strURLend run
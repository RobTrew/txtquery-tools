property pTitle : "Copy TP3 selection as tp3doc:// url"property pVer : "0.02"property pAuthor : "Rob Trew"property pDescription : "

	Copies the selected text in TaskPaper as an tp3doc:// URL 
	linking back to the current document, filter state, 
	and (if still identifiable by nodepath, search string or line number), selection.
	
	(Uses the tp3doc:// url-scheme - registered and handled by the OpenTP3DocAtLine.app applescript app bundle)

"property pstrJS : "

function(editor, options) {

var	libNodePath = require('ft/core/nodepath').NodePath,
	tree=editor.tree(),

	rngSeln = editor.selectedRange(),
	oFirstNode = rngSeln.startNode,
	dctStartOffset = rngSeln.startLineCh(),
	dctEndOffset = rngSeln.endLineCh(),

	strNodePath = editor.nodePath().toString(),
	strSelnPath = libNodePath.calculateMinNodePath(oFirstNode),
	strDocPath=options.docpath,
	strURL='', strText,
	strEncoded,

	lngLine = dctStartOffset.line,
	lngStartOffset=dctStartOffset.ch,
	lngEndOffset=-1,
	lnPosn;
	
	if (dctEndOffset.line === lngLine) {
		lngEndOffset = dctEndOffset.ch;
	}
	strURL='tp3doc://' + strDocPath;

	if (strNodePath !== '///*') {
		strURL += ('?nodepath=' + strNodePath);
	}
	if (strSelnPath.indexOf('@id') < 0) {
		strURL += ('?selnpath=' + strSelnPath);
	} 
	
	strText = oFirstNode.text();
	if (strText.length > 2) {
		strURL += ('?find=' + strText);
	}

	if (lngLine) {
		strURL += ('?line=' + lngLine.toString());
	}

	if (lngStartOffset) {
		if (lngEndOffset) {
			if (lngStartOffset !== lngEndOffset) {
				strURL += ('?startoffset=' + lngStartOffset.toString());
				strURL += ('?endoffset=' + lngEndOffset.toString());
			}
		}

	}

	return encodeURI(strURL);
}

"on run	set varResult to missing value	tell application "TaskPaper"		set lstDocs to documents		if lstDocs ≠ {} then			set oDoc to item 1 of lstDocs			tell oDoc				set strPath to POSIX path of ((file of it) as alias)				set strURL to (evaluate script pstrJS with options {docpath:strPath})				set the clipboard to strURL				display notification "tp3doc:// link copied ..."			end tell		end if	end tell	return strURLend run
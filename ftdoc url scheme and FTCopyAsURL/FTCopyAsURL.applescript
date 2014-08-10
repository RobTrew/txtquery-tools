property pTitle : "Copy FT selection as ftdoc:// url"property pVer : "0.04"property pAuthor : "Rob Trew"property pDescription : "

	Copies the selected text in FoldingText as an ftdoc:// URL 
	linking back to the current document, filter state, 
	and (if still identifiable by nodepath, search string or line number), selection.
	
	(Uses the ftdoc:// url-scheme - registered and handled by the OpenFTDocAtLine.app applescript app bundle)

"property pstrJS : "

function(editor, options) {

var	libNodePath = require('ft/core/nodepath').NodePath,
	libPasteboard = require('ft/system/pasteboard').Pasteboard,
	libNotification = require('ft/system/notificationcenter').NotificationCenter,
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
	strURL='ftdoc://' + strDocPath;

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

	strEncoded=encodeURI(strURL);
	libPasteboard.writeString(strEncoded);
	libNotification.deliverNotification('ftdoc:// link copied',
		'(for current selection and filter state)', oFirstNode.text());
	return strEncoded;
}

"on run	set varResult to missing value	tell application "FoldingText"		set lstDocs to documents		if lstDocs ≠ {} then			set oDoc to item 1 of lstDocs			tell oDoc				set strPath to POSIX path of ((file of it) as alias)				set strURL to (evaluate script pstrJS with options {docpath:strPath})			end tell		end if	end tell	return strURLend run
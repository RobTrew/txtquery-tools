property pTitle : "Move line(s) to new section"
property pVer : "0.03"
property pAuthor : "RobTrew"
property pLicense : "MIT: ALL copies should include the license notice at https://github.com/RobTrew/txtquery-tools"

property pUse : "

	1. Select one or more lines in FoldingText
	2. Run this script and choose a target section from the menu
"
-- JSLR option for additional leading tab
property pblnTaskPaperIndent : false

property pstrMoveSeln : "
	function(editor, options) {

		// FIND THE TARGET SECTION
		var oTree=editor.tree(),
			oNewParent=oTree.evaluateNodePath(options.targetpath + '[0]')[0],
			rngSeln = editor.selectedRange(),
			lstNodes = rngSeln.nodesInRange(), 
			lstSeen=[], lstSelnRoots=[], strID,
			
			// edit (1 of 2) for JSLR (using TaskPaper format in FT)
			blnExtraIndent = options.taskpaperindent;
		
		// WORK ONLY WITH THE HIGHEST LEVEL NODES IN THE SELECTION
		// (CHILDREN TRAVEL WITH THEM)
		lstNodes.forEach(function (oNode) {
			strID=oNode.parent.id;
			if (lstSeen.indexOf(strID) == -1) {
				lstSelnRoots.push(oNode);
				lstSeen.push(oNode.id);
			}
		});

		// APPEND EACH SELECTED PARENT NODE TO THE CHOSEN TARGET NODE
		// Taking children with each parent, unless we are relocating an ancestor under one
		// of its own descendants (demoted ancestors travel alone)

		lstSelnRoots.forEach(function (oNode) {
			if (oNewParent.isAncestorOfSelf(oNode)) { //detach traveller from its descendants before moving it
				oTree.removeNode(oNode);
			}
			oNewParent.appendChild(oNode); // by default children travel with parents
			
			// edit (2 of 2) for JSLR (using TaskPaper format in FT)
			if (blnExtraIndent) {oNode.setLine('\\t' + oNode.line())}
		});
	}
"

property pstrHeadingList : "

	// GATHER LIST OF SECTIONS FOR THE UI MENU
	function(editor) {
		var  libNodePath = require('ft/core/nodepath').NodePath,
			oTree = editor.tree(),
			lstHeads = oTree.evaluateNodePath('//@type=heading'),
			lstMenu = [], lstPath=[], lstSelnNodes=editor.selectedRange().nodesInRange(),
			lngSeln=lstSelnNodes.length,
			rngLines, strText='';

			if (lngSeln) {
				rngLines = oTree.createRangeFromNodes(lstSelnNodes[0],0,lstSelnNodes[lngSeln-1],-1);
				strText = rngLines.textInRange();
			}
	
			lstHeads.forEach(function(oHead) {
				lstPath.push(libNodePath.calculateMinNodePath(oHead));
				lstMenu.push(
					[
						Array(oHead.typeIndentLevel()+1).join('#'),
						oHead.text()
					].join(' ')
				);
			});
	
			return [lstMenu, lstPath, strText];
	}
"

on run
	tell application "FoldingText"
		set lstDocs to documents
		if lstDocs ­ {} then
			tell item 1 of lstDocs
				
				-- GET LIST OF HEADING TITLES AND THEIR MINIMUM PATHS
				set lstHeadsAndSeln to (evaluate script pstrHeadingList)
				set {lstTitle, lstPath, strSeln} to lstHeadsAndSeln
				if lstTitle ­ {} and strSeln ­ "" then
					
					--  GET NUMBERED LIST OF TITLES
					set lngHead to length of lstTitle
					set lngDigits to length of (lngHead as string)
					repeat with i from 1 to lngHead
						set item i of lstTitle to (my PadNum(i, lngDigits) & tab & item i of lstTitle)
					end repeat
					
					--  GET USER CHOICE
					activate
					set varChoice to choose from list lstTitle with title pTitle & tab & pVer with prompt Â
						"Choose new section for selected line(s): " & linefeed & linefeed & strSeln & linefeed default items {item 1 of lstTitle} Â
						OK button name "OK" cancel button name "Cancel" with empty selection allowed without multiple selections allowed
					if varChoice = false then return missing value
					set varChoice to item 1 of varChoice
					
					--  GET INDEX OF USER CHOICE
					set {dlm, my text item delimiters} to {my text item delimiters, tab}
					set iChoice to text item 1 of varChoice
					set my text item delimiters to dlm
					
					--  GET TITLE AND MINIMUM NODEPATH OF CHOSEN SECTION
					set {strTitle, strPath} to {item iChoice of lstTitle, item iChoice of lstPath}
					
					-- MOVE SELECTED LINES TO CHOSEN SECTION
					-- JSLR edit (added taskpaperindent:pblnTaskPaperIndent option for additional leading tab
					evaluate script pstrMoveSeln with options {targetpath:strPath, taskpaperindent:pblnTaskPaperIndent}
				end if
			end tell
		end if
	end tell
end run

on PadNum(lngNum, lngDigits)
	set strNum to lngNum as string
	set lngGap to (lngDigits - (length of strNum))
	repeat while lngGap > 0
		set strNum to "0" & strNum
		set lngGap to lngGap - 1
	end repeat
	return strNum
end PadNum

// Yosemite JavaScript for Applications (JXA) version
function run() {

	var dctScript = {
		title: "Move line(s) to new section",
		version: "0.04",
		author: "RobTrew",
		license: "MIT: ALL copies should include the license notice at https://github.com/RobTrew/txtquery-tools"
	}

	var blnDebug = 0; // zero unless using the symbolic debugger


	// JSLR
	// edit to `blnTPIndent = true` for an extra TaskPaper indent - false for default formatting
	var blnTPIndent = false; 


	var docsFT = Application("FoldingText").documents(),
		oDoc = docsFT.length ? docsFT[0] : null;

	if (!oDoc) return null;


	// GET LIST OF HEADING TITLES AND THEIR MINIMUM PATHS (+ any selected text) 
	var fnProcess = (blnDebug ? oDoc.debug : oDoc.evaluate),
		lstHeadsAndSeln = fnProcess({
			script: sectionList.toString()
		}),
		lstMenu = lstHeadsAndSeln[0],

		lstSectionPaths = lstHeadsAndSeln[1],
		strSeln = lstHeadsAndSeln[2],
		lstNumberedMenu = numberedMenu(lstMenu);

	// Exit here, if the document contains no headers
	if (!lstNumberedMenu.length) return 0;

	// GET USER CHOICE
	var app = Application.currentApplication(),
		mbChoice, varResult;

	app.includeStandardAdditions = true;

	mbChoice = maybeChoiceIndex(
		app.chooseFromList(lstNumberedMenu, {
			withTitle: dctScript.title,
			withPrompt: "Choose new section for selected line(s):\n\n" + strSeln +
				"\n",
			defaultItems: lstNumberedMenu[0],
			okButtonName: "Move",
			cancelButtonName: "Cancel",
			multipleSelectionsAllowed: false,
			emptySelectionAllowed: false,
		})
	);


	// IF A TARGET SECTION HAS BEEN CHOSEN, MOVE THE SELECTION
	if (mbChoice) {
		return fnProcess({
			script: itemMove.toString(),
			withOptions: {
				// JSLR
				taskpaperindent: blnTPIndent,
				targetpath: lstSectionPaths[mbChoice]
			}
		});
	} else return null;
}

// Number of any target section chosen, or null if no choice
function maybeChoiceIndex(varResult) {
	return varResult ?
		parseInt(varResult[0].split('\t')[0]) : null;
}

// move selected item(s) to target path
function itemMove(editor, options) {

	// FIND THE TARGET SECTION
	var oTree = editor.tree(),
		oNewParent = oTree.evaluateNodePath(options.targetpath + '[0]')[0],
		rngSeln = editor.selectedRange(),
		lstNodes = rngSeln.nodesInRange(),
		lstSeen = [],
		lstSelnRoots = [],
		strID,

		// edit (1 of 2) for JSLR (using TaskPaper format in FT)
		blnExtraIndent = options.taskpaperindent;

	// WORK ONLY WITH THE HIGHEST LEVEL NODES IN THE SELECTION
	// (CHILDREN TRAVEL WITH THEM)
	lstNodes.forEach(function (oNode) {
		strID = oNode.parent.id;
		if (lstSeen.indexOf(strID) == -1) {
			lstSelnRoots.push(oNode);
			lstSeen.push(oNode.id);
		}
	});

	// APPEND EACH SELECTED PARENT NODE TO THE CHOSEN TARGET NODE
	// Taking children with each parent, unless we are relocating an ancestor under one
	// of its own descendants (demoted ancestors travel alone)

	lstSelnRoots.forEach(function (oNode) {
		if (oNewParent.isAncestorOfSelf(oNode)) //detach traveller from its descendants before moving it
			oTree.removeNode(oNode);

		oNewParent.appendChild(oNode); // by default children travel with parents

		// edit (2 of 2) for JSLR (using TaskPaper format in FT)
		if (blnExtraIndent)
			oNode.setLine('\t' + oNode.line())
	});
}

// GATHER LIST OF SECTIONS FOR THE UI MENU
function sectionList(editor) {
	var libNodePath = require('ft/core/nodepath').NodePath,
		oTree = editor.tree(),
		lstHeads = oTree.evaluateNodePath('//@type=heading'),
		lstSelnNodes = editor.selectedRange().nodesInRange(),
		lngSeln = lstSelnNodes.length;

	var lstMenu = [],
		lstPath = [],
		strText = '',
		rngLines;


	// get any selected text
	if (lngSeln) {
		rngLines = oTree.createRangeFromNodes(lstSelnNodes[0], 0, lstSelnNodes[
			lngSeln - 1], -1);
		strText = rngLines.textInRange().trim();
	}


	// and get each heading, plus its full outline path (compressed)
	lstHeads.forEach(function (oHead) {
		// header title
		lstMenu.push(
					[Array(oHead.typeIndentLevel() + 1).join('#'),
						oHead.text()
					].join(' ')
		);
		// and compressed header path
		lstPath.push(libNodePath.calculateMinNodePath(oHead));
	});


	// headers, their outline paths, and any selected text
	return [lstMenu, lstPath, strText];
}


// List of strings re written with zero-padded numeric prefixes
// [strItem] ? maybeStringSeparator ? [strNumberedItem]
function numberedMenu(lstItems, strSeparator) {
	// default separator between number string and item string
	strSeparator = strSeparator || '\t';

	var lng = lstItems.length,
		lngPadWidth = lng.toString().length;

	// Numbers string padded to left with zeros to get fixed width
	// intNumber --> intDigits --> strDigits
	function zeroPad(intNumber, intDigits) {
		var strUnpadded = intNumber.toString(),
			intUnpadded = strUnpadded.length;

		return Array((intDigits - intUnpadded) + 1).join('0') + strUnpadded;
	}

	// list rewritten with numeric prefixes of even length
	// left-padded with zeros where needed
	return lstItems.map(function (str, i) {
		return zeroPad(i, lngPadWidth) + strSeparator + str;
	});
}
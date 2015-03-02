// Translate BML HTML file (or clipboard contents) to FT / MD text
// and copy output to clipboard, or save as text file.

// RobTrew 2015

// Ver 0.2

function run() {
	'use strict';
	// REWRITE UNORDERED HTML LIST WITH KEY-VALUE ATTRIBUTES -->  FT/MD @tagged TXT

	// OPTIONS

	var blnReadClipboard = false; // otherwise (or if no <UL><LI> clipped) choose an input file from dialog
	var blnWriteClipboard = false; // otherwise Save As through Chose File dialog
	
	var blnIDTags = false; // write id attributes to MD as @id(xxxxxxxxx) ?

	var strOutExtn = "txt";


	// four stages:

	// 1. OBJC BRIDGE: NS XML PARSE //////////////////////////
	// [ Path  | Clipboard ] --> strHTML
	// strHTML --> $.NSXMLParse


	// 2. ROOT <UL> and [expansion ids] //////////////////////
	// $.NSXMLParse --> [head.meta, body]
	// head.meta --> [id]  // ids of expanded nodes 
	// body --> [[li]]


	// 3. NESTED JS OBJECT ( FORMAT COMMON TO VARIOUS SCRIPTS )
	// [[li]] --> [[{jso}]]
	// [li] --> [{txt:'' chiln:[] tags:{}}]
	// <li> --> [[attribute], <p>, maybe <ul>]
	// [attribute] --> {tags:{}, id:''}
	// <p> --> {txt: }


	// 4. JSO --> STRMD ///////////////////////////////////////
	//{txt:String, chiln:Array, id:String, tags:Object} --> strMD
	// strMD --> [ path | clipboard ]::IO




	// VARIABLES SHARED ACROSS FUNCTIONS
	// Simple regexes for contents of <p> </p>
	var rgxB = /<\/?[bB]>/g,
		rgxI = /<\/?[iI]>/g,
		rgxBirds = /></g; // NSXML seems to drop single spaces between tags

	var lstUnfolded = [];


	// FUNCTIONS


	// (1 of 4) OBJC BRIDGE: NS XML PARSE ////////////////////
	// [ Path  | Clipboard ] --> strHTML

	// strPath --> strHTML
	function readTextFromFile(strPath) {
		return ObjC.unwrap($.NSString.stringWithContentsOfFile(strPath));
	}

	// strHTML --> $.NSXMLParse
	function xmlParse(strHTML) {
		return $.NSXMLDocument.alloc.initWithXMLStringOptionsError(
			strHTML, 0, null
		);
	}

	// (2 of 4) ROOT <UL> and [expansion ids] ////////////////

	// $.NSXMLParse --> [head.meta, body]
	function metaAndBody(oXMLDoc) {
		var lstTop = ObjC.unwrap(oXMLDoc.rootElement.children),
			i = lstTop.length,
			dct = {},
			oXMLNode, lstHead, oHeadNode, strName, j;

		while (i--) {
			oXMLNode = lstTop[i];
			strName = ObjC.unwrap(oXMLNode.name);
			if (strName === 'head') {
				lstHead = ObjC.unwrap(oXMLNode.children);

				j = lstHead.length;
				while (j--) {
					oHeadNode = lstHead[j];
					if (ObjC.unwrap(oHeadNode.name) === 'meta') {
						dct.meta = oHeadNode;
						break;
					}
				}
			} else if (strName === 'body') {
				dct.body = ObjC.unwrap(oXMLNode.children);
			}
		}
		return dct;
	}


	// <meta name="expandedItems" content="GDRiLbMho W27PjQq1W bveZ6LbhN" />
	// head.meta --> [id]  // ids of expanded nodes 
	function expansionIDs(oXMLNode) {
		var strTitle = ObjC.unwrap(
				oXMLNode.attributeForName('name').stringValue
			),
			varIDList = (strTitle === 'expandedItems') ?
			ObjC.unwrap(
				oXMLNode.attributeForName('content').stringValue
			) : null;

		return varIDList ? varIDList.split(' ') : [];
	}


	// body --> [[li]]
	function bodyULs(lstBody) {
		var lstLI = [];

		for (var i = 0, lng = lstBody.length; i < lng; i++) {
			lstLI.push(
				ObjC.unwrap(
					lstBody[i].children
				)
			);
		}
		return lstLI;
	}


	// (3 of 4) NESTED JS OBJECT ( DETOUR, BUT A FORMAT COMMON TO VARIOUS SCRIPTS, SO REUSABLE ... )

	//[li] --> [{txt:'' chiln:[] tags:{} id:''}]
	function liList(lstUlChiln) {
		var lngPreserveSpace = $.NSXMLNodePreserveWhitespace,
			oLI, lstNode, lngNode, oChild, strName, strText,
			dctTags;

		for (var i = 0, lng = lstUlChiln.length; i < lng; i++) {

			oLI = lstUlChiln[i];
			lstNode = ObjC.unwrap(oLI.children);
			lngNode = lstNode.length;

			strText = ObjC.unwrap(lstNode[0].XMLString);
			// <p> --> '' <b> --> **,  <i> --> * 
			strText = strText.substring(
				3, strText.length - 4
			).replace(rgxBirds, '> <').replace(rgxB, '**').replace(rgxI, '*');

			dctTags = liTags(oLI.attributes);

			lstUlChiln[i] = (lngNode > 1) ? { // parent: <p> followed by <UL>
				txt: strText,
				tags: dctTags,
				chiln: liList(ObjC.unwrap(lstNode[1].children)),
				fold: lstUnfolded.indexOf(dctTags.id) !== -1
			} : { // leaf
				txt: strText,
				tags: dctTags,
			};
		}
		return lstUlChiln;
	}

	//[xmlAttribs] --> dctTags
	function liTags(xmlAttribs) {
		var lstAttrib = ObjC.unwrap(xmlAttribs),
			k = lstAttrib.length,
			dct = {},
			oTag;

		while (k--) {
			oTag = lstAttrib[k];
			dct[ObjC.unwrap(oTag.name)] = ObjC.unwrap(oTag.stringValue);
		}
		return dct;
	}

	// (4 of 4) JSO --> STRMD ///////////////////////////////////////

	// [{txt: chiln: tags:}] --> strMD
	function jsoListMD(lstTree, strIndent) {
		var lng = lstTree.length,
			strMD = '',
			strNxtIndent = strIndent + '\t',
			dctTree, lstChiln, dctTags, i;

		for (i = 0; i < lng; i++) {
			dctTree = lstTree[i];
			strMD = strMD + strIndent + "- " + dctTree.txt + nodeTags(dctTree.tags) +
				'\n';
			lstChiln = dctTree.chiln;
			if (lstChiln) strMD = strMD + jsoListMD(lstChiln, strNxtIndent);
		}
		return strMD;
	}

	// {tag1:, tag2:, tagN:} --> "@tag1(value) @tag2(value) tagN" + maybe "@id(xxxxxxxxx)"
	function nodeTags(dctTags) {
		var lstKeys = Object.keys(dctTags),
			strID = dctTags.id,
			idxID = lstKeys.indexOf('id'),
			str = '',
			strKey, varVal;

		if (idxID !== -1)
			lstKeys.splice(idxID, 1);

		lstKeys.sort();
		for (var i = 0, lng = lstKeys.length; i < lng; i++) {
			strKey = lstKeys[i];
			varVal = dctTags[strKey];
			str = str + ' @' + strKey + (varVal ? "(" + varVal + ")" : '');
		}
		if (idxID && blnIDTags)
			str = str + " @id(" + dctTags.id + ")";

		return str;
	}

	function isBirchUL(strText) {
		return ((strText.indexOf('<!DOCTYPE html>') === 0) &&
			(strText.indexOf('<ul') !== -1))
	}



	///////// Main

	// world --> new world
	// 1. Get some material from file or clipboard,
	// 2. apply some rewrite rules to it,
	// 3. and copy the result to file or clipboard.

	function main() {
		var app = Application.currentApplication(),
			strOutName = 'Untitled.' + strOutExtn,
			dctHTML, strText, strHTML, strInPath, strOutPath,
			strInName, strMD, fm, strStem, nsMD, strMsg;

		// 1. GET HTML SOURCE

		app.includeStandardAdditions = true;
		if (blnReadClipboard) {
			// Any string in the clipboard ?
			if (app.clipboardInfo({
					for: "string"
				}).length) {
				strText = app.theClipboard({
					as: "string"
				});
				if (isBirchUL(strText)) {
					strHTML = strText;
				}
			};
		}

		if (!strHTML)
			strInPath = (
				app.chooseFile({
					withPrompt: "Choose <UL><LI> HTML file:"
				})
			).toString(),
			strHTML = strInPath ? readTextFromFile(strInPath) : '';
		if (!strHTML) return;


		// 2. TRY TO PARSE AS Birch UL/LI 

		dctHTML = metaAndBody(
			xmlParse(strHTML)
		);
		lstUnfolded = expansionIDs(dctHTML.meta);


		// 3. REWRITE AS MD
		strMD = jsoListMD(
			liList(
				bodyULs(dctHTML.body)[0] // just 1 root UL
			), '' // initial indent
		);


		// 4. PUT THE MD IN CLIPBOARD OR FILE
		if (blnWriteClipboard) {
			strMsg = "MD written to clipboard ...";
			app.setTheClipboardTo(strMD);
			app.displayNotification(strMsg, {
				withTitle: "UL HTML --> MD ",
				subtitle: "Copied to clipboard as @tagged FT/MD)",
				sound: "Glass"
			});
		} else {
			if (strInPath) {
				fm = $.NSFileManager.defaultManager;
				strInName = ObjC.unwrap(fm.displayNameAtPath(strInPath));
				strStem = strInName.split('.')[0];
				strOutName = strStem + '.' + strOutExtn;
			}
			strOutPath = app.chooseFileName({
				withPrompt: "Save as MD/FT",
				defaultName: strOutName
			}).toString();

			nsMD = $.NSString.alloc.initWithUTF8String(strMD);
			nsMD.writeToFileAtomically(strOutPath, true);
			strMsg = "MD saved to " + strOutName;
			app.displayNotification(strMsg, {
				withTitle: "UL HTML --> MD ",
				subtitle: "Saved as @tagged FT/MD)",
				sound: "Glass"
			});
		}

		return strMsg;
	}

	return main()
}
function run() {
	'use strict';
	/* jshint multistr: true */
	var pTitle = "FT save as Birch bml/html outline",
		pVer = "0.14",
		pAuthor = "Rob Trew",
		pSite = "https://github.com/RobTrew/txtquery-tools",
		pComment =
		"\
			- Preserves the FoldingText outlining expansion state in the ul.\
			- Each <li> has a <p> element, and may have a nested <ul>\
			- FoldingText @key(value) pairs become <li> attributes with string values\
			- FoldingText @tags with no value ? <li> attributes with value 1\
			\
			- This version uses CommonMark rather than FT line type names for\
			  compatibility with Jesse Grosjean's Birch-Markdown package\
		",
		pblnDebug = 0,
		pblnToFile = 1, // SAVE AS AN BML FILE ?
		pblnToClipboard = 0; // COPY BML TO CLIPBOARD ?


	//OPTIONS: 

	//Export the whole document, or just the subtree(s) of any selected line(s) ?
	var pblnWholeDoc = true;

	// Default folder for Save As dialog ?
	//var pOutFolder = appSA.pathTo('desktop');
	// or e.g.  
	// 	var pOutFolder=Path("/Users/houthakker/docs")
	var pOutFolder = null; // defaults to most recent folder

	// FoldingText code	(to be passed as string, with options, to FT.evaluate() ...)	
	var fnScript =
		function (editor, options) {
			// FoldingText code here

			// SHARED REGEXES
			var rgxAmp = /&/g,
				rgxApos = /\'/g,
				rgxQuot = /\"/g,
				rgxLt = /</g,
				rgxGt = />/g,
				rgxCode = /`([^\n\r]+)`/g,
				rgxBold = /\*\*([^\*\n\r]+)\*\*/g,
				rgxItalic = /[\*_]([^\*_\n\r]+)[\*_]/g,
				rgxImage = /!\[([^\]]*)]\(([^(]+)\)/g,
				rgxLink = /\[([^\]]+)]\(([^(]+)\)/g;


			// FIND THE ROOT NODES AMONG THE SELECTED LINES
			// (Ignoring any children of lines already seen)

			// editorState --> [ftNode]
			function selectedRoots() {
				var lstRoots = [],
					lstSeen = [];

				editor.selectedRange().forEachNodeInRange(function (oNode) {
					if (oNode.type() !== 'empty') {
						if (lstSeen.indexOf(oNode.parent.id) === -1) lstRoots.push(oNode);
						lstSeen.push(oNode.id);
					}
				});
				return lstRoots;
			}

			// Intermediate JSO format used in various scripts
			// [ftNode] --> [{text:strText, nest:[<recursive>, , ], fold:bool}]
			function textNest(lstNodes, oParent) {
				var lstNest = [],
					lstKeys, dctKeyVal,
					dctNode, oNode, dctTags, strKey, k;

				for (var i = 0, lng = lstNodes.length; i < lng; i++) {
					oNode = lstNodes[i];
					if (oNode.type() !== 'empty') {
						dctNode = {
							text: oNode.text(),
							line: oNode.line(),
							posn: oNode.lineTextStart(),
							type: oNode.type(),
							parent: oParent
						};

						dctTags = oNode.tags();
						for (k in dctTags) { // ie only if object not empty
							dctNode.tags = dctTags;
							break; // one test only - no loop
						}

						if (oNode.hasChildren()) {
							dctNode.fold = editor.isCollapsed(oNode);
							dctNode.nest = textNest(oNode.children(), oNode);
						}
						lstNest.push(dctNode);
					}
				}
				return lstNest;
			}





			// TRANSLATE A LIST OF {txt, chiln} NODES AND THEIR DESCENDANTS INTO UL
			function ulTranslation(lstRoots) {

				var lstUlHead = [
						'<!DOCTYPE html><html xmlns="http://www.w3.org/1999/xhtml">',
						'  <head>',
						'    <meta name="expandedItems" content="'
					],
					lstUlPostExpand = [
						'" />',
						'    <meta charset="UTF-8" />',
						'    <style type="text/css">p { white-space: pre-wrap; }</style>',
						'  </head>',
						'  <body>',
						'    <ul id="Birch.Root">\n'
					],
					lstUlTail = [
						'    </ul>',
						'  </body>',
						'</html>'
					],
					strUlStart = '<ul>\n',
					strUlClose = '</ul>\n',
					strLiStart = '<li',
					strLiClose = '</li>\n',
					strPStart = '<p>',
					strClose = '>\n',
					strPClose = '</p>\n',
					strLeafClose = '/>\n',
					strParentClose = '>\n',
					strHead = lstUlHead.join('\n'),
					strTail = lstUlTail.join('\n'),
					strOutline = '',
					strUL, lstUL,
					lngRoots = lstRoots.length,
					i,
					lstFolds = [],
					iLine = 0;

				// REWRITE TO RECURSE WITH CHILD RANGES RATHER THAN PARENTS - LESS RECURSION NEEDED

				// WRITE OUT A LIST OF NODES AS ELEMENTS, WRAPPING ANY CHILDREN AS UL
				// <li> contains a <p> and may contain a <ul> wrapping an <li> child sequence
				function ulOutline(lstNest, strIndent, blnHidden) {
					var strOut = '',
						strDeeper = strIndent + '  ',
						strChildIndent = strDeeper + '  ',
						blnCollapsed = blnHidden,
						blnFencing = false,
						dctTags, lstChiln, dctNode, oChild,
						strKey, strID, strTypePfx, strType, strText, strLang;



					for (var i = 0, lng = lstNest.length; i < lng; i++) {
						dctNode = lstNest[i];

						// Locally unique identifier [A-Za-z0-9_]{8}
						strID = localUID(8);
						strOut = strOut + strIndent + strLiStart + ' id="' + strID + '"';

						// Any CommonMark name of FT type of node
						strType = cmName(dctNode.type);
						if (strType)
							strOut = strOut + ' data-type="' + strType + '"';


						strTypePfx = strType.substring(0, 2);
						if (blnFencing || strTypePfx === 'fe') {

							if (strType.length > 10) {
								strText = '';
								blnFencing = (strType === 'fencedcodetopboundary');
								if (blnFencing) {
									strLang = dctNode.text.substring(3).trim();
									if (strLang)
										strOut = strOut + ' data-language="' + strLang + '"';
								}
							} else strText = entityEncoded(dctNode.line);
						} else strText = mdHTML(dctNode.text);


						// ANY FURTHER ATTRIBUTES OF THE LI
						dctTags = dctNode.tags;
						if (dctTags) {
							for (strKey in dctTags) {
								if (strKey !== 'language') { //??
									strOut = strOut + ' data-' + strKey +
										'=' + quoteAttr(dctTags[strKey]);
								}
							}
						}


						strOut = strOut + strParentClose + strDeeper +
							strPStart + strText + strPClose;

						// wrap any children in a <ul> before closing the <li>
						lstChiln = dctNode.nest;
						if (lstChiln) {
							// Collect any ul ExpansionState id
							if (!blnHidden && !dctNode.fold) lstFolds.push(strID);
							else blnCollapsed = true;
							iLine++; // before the recursive descent

							// wrap child <li> sequence in <ul> ... </ul>
							strOut = strOut +
								strDeeper + strUlStart +
								ulOutline(lstChiln, strChildIndent, blnCollapsed) +
								strDeeper + strUlClose;
						} else iLine++;

						strOut = strOut + strIndent + strLiClose;
					}

					return strOut;
				}

				// WALK THROUGH THE TREE, BUILDING AN ul OUTLINE STRING
				strOutline = ulOutline(lstRoots, '      ', false);

				// ASSEMBLE THE HEADER,
				// INCLUDING THE EXPANSION DIGITS COLLECTED DURING RECURSION
				strHead = strHead + lstFolds.join(' ') + lstUlPostExpand.join('\n');

				// AND COMBINE HEAD BODY AND TAIL
				strUL = [strHead, strOutline, strTail].join('');
				//strUl = strOutline;
				return strUL;
			}

			// Letters at start of FT type names [for cmName()]
			var C = 99,
				E = 101,
				F = 102,
				H = 104,
				L = 108,
				N = 110,
				O = 111,
				R = 114;


			// strFoldingTextTypeName --> strCommonMarkTypeName
			function cmName(str) {
				var iInit = str.charCodeAt(0),
					iNext = str.charCodeAt(1),
					strName = '';

				if (iInit > H) {
					if (iInit > O && (iNext === N)) strName = 'Bullet';
					else if (iNext === R) strName = 'Ordered';
				} else if (iInit < H) {
					if (iInit === F && (iNext === E)) strName = 'CodeBlock';
					else if (iInit < C) {
						if (iNext === L) strName = 'BlockQuote';
						else if (iNext === O) strName = 'Paragraph';
					} else if (iInit === C) strName = 'CodeBlock';
				} else {
					if (iNext < O) strName = 'Header';
					else if (iNext > O) strName = 'HtmlBlock';
					else strName = 'HorizontalRule';
				}
				return strName;
			}

			// strMDLink.replace.match --> strOut
			function fnLinkMD2HTML(match, p1, p2) {
				return '<a href=' + quoteAttr(p2) + '>' + p1 + '</a>';
			}

			// strMDImg.replace.match --> strOut
			function fnImgMD2HTML(match, p1, p2) {
				return '<img alt=' + p1 + ' src=' + quoteAttr(p2) + '>';
			}

			// ** --> <b>; * --> <i>, ` --> <code>, []() --> <a> ![]() --> <img> 
			function mdHTML(strMD) {
				if (strMD !== '```') {
					return strMD.replace(
						rgxBold, '<b>$1</b>'
					).replace(
						rgxItalic, '<i>$1</i>'
					).replace(
						rgxCode, '<code>$1</code>'
					).replace(
						rgxImage, fnImgMD2HTML
					).replace(
						rgxLink, fnLinkMD2HTML
					);
				} else return '';
			}



			// n --> strRandom  (first alphabetic, then AlphaNumeric | '_'
			function localUID(lngChars) {
				var strAlphaSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
					strOtherSet = "0123456789_",
					strFullSet = strAlphaSet + strOtherSet,
					lngFull = strFullSet.length,
					str = strAlphaSet.charAt(Math.random() * strAlphaSet.length | 0),
					lngRest = lngChars - 1;

				while (lngRest--)
					str = str + strFullSet.charAt(Math.random() * lngFull | 0);
				return str;
			}

			// str --> str
			function quoteAttr(s) {
				return '"' + (('' + s) /* Forces the conversion to string. */
					.replace(rgxAmp, '&amp;') /* This MUST be the 1st replacement. */
					.replace(rgxApos, '&apos;') /* The 4 other predefined entities, required. */
					.replace(rgxQuot, '&quot;')
					.replace(rgxLt, '&lt;')
					.replace(rgxGt, '&gt;')) + '"';
			}

			// str --> str
			function entityEncoded(str) {
				return str.replace(/[\u00A0-\u9999<>\&]/gim, function (i) {
					return '&#' + i.charCodeAt(0) + ';';
				});
			}

			//////// FT MAIN

			var lstRoots; //, lstTextTree; //, strHTML;

			// EXPORT WHOLE DOC ? OR JUST THE SELECTED LINE(S) AND ALL ITS/THEIR DESCENDANTS ?
			if (options.wholedoc)
				lstRoots = editor.tree().evaluateNodePath('/@type!=empty');
			else lstRoots = selectedRoots();

			//lstTextTree = textNest(lstRoots); 

			// strHTML = ulTranslation(
			// 	textNest(lstRoots), quoteAttr(options.title)
			// );

			return ulTranslation(
				textNest(lstRoots)
			);
		};

	//// run() FUNCTION(S)
	function chooseOutPath(oApp, oDocPath, strExtn) {
		var oFM = $.NSFileManager.defaultManager,
			pathLocn = pOutFolder, //module default
			pathOut = null,
			strName = oFM.displayNameAtPath(oDocPath.toString()).js,
			lstName = strName.split('.'),
			lngName = lstName.length,
			lstStem = lstName.slice(0, lngName - 1),
			strStem = lstName[0];

		if (!pathLocn || !oFM.fileExistsAtPathIsDirectory(pathLocn.toString(), null))
			pathLocn = oDocPath;

		// draft new name by substituting or affixing strExtn
		if (1 < lngName) {
			lstStem.push(strExtn);
			strName = lstStem.join('.');
		} else strName += '.' + strExtn;

		// show file name dialog
		oApp.activate();
		pathOut = oApp.chooseFileName({
			withPrompt: pTitle,
			defaultName: strName,
			defaultLocation: pathLocn
		});
		return [pathOut, strStem];
	}

	//////// run() MAIN
	var appFT = new Application("FoldingText"),
		app = Application.currentApplication(),
		lstDocs = appFT.documents(),
		oDoc = lstDocs.length ? lstDocs[0] : null,
		fnProcess,
		oPath,
		strBaseName,
		strFTPath, pathOML = null,
		lstPathStem = [null, null],
		pathul = null,
		strUL,
		nsul = null,
		strUlPath = '',
		strMsg = '';

	app.includeStandardAdditions = true

	if (oDoc) {
		appFT.activate();
		appFT.includeStandardAdditions = true;

		fnProcess = (pblnDebug ? oDoc.debug : oDoc.evaluate);
		strUL = fnProcess({
			script: fnScript.toString(),
			withOptions: {
				wholedoc: pblnWholeDoc
			}
		});


		if (strUL.indexOf('<!DOCTYPE html>' !== 1)) {
			if (pblnToClipboard) {

				app.activate();
				app.setTheClipboardTo(strUL);
				app.displayNotification(oDoc.name(), {
					withTitle: "FoldingText to BML",
					subtitle: "Copied to clipboard as BML (HTML <UL> nest)",
					sound: "Glass"
				});
			}
			if (pblnToFile) {
				// PROMPT FOR AN EXPORT FILE PATH
				oPath = oDoc.file();
				if (oPath) {
					lstPathStem = chooseOutPath(appFT, oPath, 'bml');
					pathul = lstPathStem[0];
					if (pathul) {
						strUlPath = pathul.toString();
						nsul = $.NSString.alloc.initWithUTF8String(strUL);
						nsul.writeToFileAtomicallyEncodingError(
							strUlPath, false, $.NSUTF8StringEncoding, null);
					}
				} else strMsg =
					"Save active file before exporting to BML (HTML <UL>) outline ...";
			}
		} else strMsg = strUL;

	} else strMsg = "No FoldingText documents open ...";


	if (strMsg) {
		var app = Application.currentApplication();
		app.includeStandardAdditions = true;
		app.displayDialog(strMsg, {
			withTitle: [pTitle, pVer].join('\t'),
			buttons: ["OK"],
			defaultButton: "OK"
		});
		return false;
	}
	return "Saved to " + strUlPath;
}
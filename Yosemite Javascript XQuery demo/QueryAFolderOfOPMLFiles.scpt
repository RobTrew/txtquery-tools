JsOsaDAS1.001.00bplist00ÑVscript_"// Simple demonstration of using XQuery from OS X Yosemite Javascript for Applications// To get a menu of custom perspectives across several files (using OS X (NSXML) XQUERY from Javascript):// 1. Copy the accompanying OPML files (tagged with attributes from FoldingText / TaskPaper) into a folder// 2. Run this script, choosing (from the dialog which pops up) the folder containing the OPML files// Copyright Robin Trew Feb 2015 function run() {	'use strict';	/* jshint multistr: true */	// OPEN OUTPUT IN [Marked 2](http://marked2app.com) ?	var blnOpenPerspectiveInMarked = true;	// OPEN SOURCE FILE FOR SELECTED ACTIONS ?	var blnOpenSelected = false;	// Temporary output file for "Marked 2.app" to preview	var strTestFile = "~/Desktop/TestXQuery01.txt"; // WILL BE OVERWRITTEN - CHECK THAT THIS DOESN'T CLASH 	// EXTENSION OF <XML/HTML> FILES TO QUERY	var strExtn = "opml";	var strExtnUpper = strExtn.toUpperCase();	// MENU OF CUSTOM PERSPECTIVES - DEFINED (OVER A SET OF OPML FILES) IN NSXMLNODE XQUERY 1.0	var dctXQuery = {		'Grouped by Priority level - sorted by descending @due date': ' \			let $v := distinct-values(//outline/@priority) \			for $i in $v \			order by $i \			return ( \				concat("\n### <font color=red>Priority ", $i, "</font>"), \				for $o in //outline[@priority=$i] \				let $d := $o/@due \				order by $d empty greatest \				return ( \					concat( \						"- ", $o/@text, \						if ($d) then concat(" @due(<b>",$d,"</b>)")  else () \					) \				) \			)',
					'Starting in March': ' \			let $v := distinct-values( \
				//outline[@start > "2015-02-30" and @start < "2015-04-01"]/substring(@start,1,10) \
			) \			for $d in $v \			order by $d \			return ( \				concat("\n#### <font color=silver>", substring($d, 1, 7), "</font> <font color=red>", substring($d, 9), "</font>"), \				for $o in //outline[@start=$d]\				let $r := $o/ancestor::outline[@file], \					$f := $r/@file, \					$fp := $r/@path, \					$t := $o/@text \				order by $t \				return ( \					concat( \						"- ", $t, \						" [", $f, "](file://", $fp, $f, ")" \					) \				) \			)',		'Immediate priorities': ' \
			let $v := distinct-values(//outline[@priority=1 and @due]/substring(@due,1,10)) \
				for $d in $v \
				let $dte := xs:date($d), \
					$e := xs:date("1901-01-06") \
				order by $d \
				return (\
					concat( \
						"\n#### <font color=gray>", \
						("Sun", "Mon", "Tue", "Wed","Thu", "Fri", "Sat")[ \
							(days-from-duration($dte - $e) mod 7) + 1 \
						], \
						"</font> <font color=silver>", substring($d, 1, 7), \
						"</font> <font color=red>", substring($d, 9, 2), "</font> " \
					), \
					for $i in //outline[@priority=1 and starts-with(@due, $d)] \
					let $it := $i/@due, \
						$t := substring($it, 12), \
						$tme := if ($t) then xs:time(concat($t, ":00")) else xs:time("00:00:00")\
					order by $t empty least \
					return concat( \
						if ($t) then concat("<b>",$t,"</b> ") else (), \
						$i/@text \
					) \
				)',		'Due and urgent': ' \				for $p in //outline[@priority=1 and @due] \				let $d := $p/@due, \					$r := $p/ancestor::outline[@file], \					$f := $r/@file, \					$fp := $r/@path \				order by $d \				return concat( \					"- ", $p/@text, " ", \					if ($d) then \						concat("<font color=gray>@due(<font color=red>", $d, "</font>)</font>") \					else (), \					" [", $f, "](file://", $fp, $f, ")" \				)',		'Projects with alert dates': ' \				for $p in //outline[@type="heading" and @alert] \				let $a := $p/@alert, \					$r := $p/ancestor::outline[@file], \					$f := $r/@file, \					$fp := $r/@path \				order by $a \				return concat( \					"- ", $p/@text, " ", \					"<font color=gray>@alert(<font color=red>", $a, "</font>)</font>", \					" [", $f, "](file://", $fp, $f, ")" \				)'	};	// strPath --> [strFileName]
	function filesInFolder(strPath) {		var lstFiles = ObjC.unwrap(
				$.NSFileManager.defaultManager.contentsOfDirectoryAtPathError(
					strPath, null
				)
			),
			i = lstFiles.length;		while (i--) lstFiles[i] = ObjC.unwrap(lstFiles[i]);		return lstFiles;	}	// strFolderPath --> strExtension --> [strFilePath]	function filesInFolderWithExtn(strPath, strExtn) {		var lst = filesInFolder(strPath),			lstMatch = [],			strBase = (strPath.charAt(strPath.length - 1) === '/') ?			strPath : strPath + '/',			strFileName, lstParts, lngParts,
			i = lst.length;		while (i--) {			strFileName = lst[i];			lstParts = strFileName.split('.');			lngParts = lstParts.length;			if ((lngParts > 1) && (lstParts[lngParts - 1] === strExtn))				lstMatch.push(strBase + strFileName);		}
		console.log(lstMatch);		return lstMatch;	}	// XInclude LIST OF FILES TO INCLUDE IN THE COMPOSITE NSXMLDOCUMENT WHICH WE WILL QUERY	// [filePath] --> strWrapElementName --> strInnerElementName --> strIncludeXML	function xIncludeXML(lstFilePaths, strWrapElement, strInnerElement) {
		var strXML = '<?xml version="1.0" encoding="utf-8"?>\n<' + strWrapElement +
			' xmlns:xi="http://www.w3.org/2003/XInclude">\n',
			i = lstFilePaths.length,
			lstParts, strPath, strFile;

		while (i--) {
			strPath = lstFilePaths[i];
			lstParts = strPath.split('/');
			strFile = encodeURI(lstParts.pop());

			strXML = strXML + '\t<' + strInnerElement + ' text="" path="' +
				encodeURI(lstParts.join('/')) + '/" file="' + strFile + 
				'">\n\t\t<xi:include href="' + encodeURI('file://' + strPath) +
				'"/>\n\t</' + strInnerElement + '>';
		}

		strXML = strXML + '\n</' + strWrapElement + '>';
		return strXML;
	}	/////// MAIN ////////////////////////////////////////////////////////////////////////////////////	var rgxFileURL = /\((file.*)\)$/,		varChoice = true,		oMatch, docXML,		lstMenu, lst, lstFiles,		strURL, strMenuKey, strTitle, strXML, strTXT, strPATH,		lng, i,		blnWritten;	// PREPARE FOR USE OF DIALOGS	var app = Application.currentApplication();	app.includeStandardAdditions = true;	app.activate();	// CHOOSE THE FOLDER CONTAINING THE FOUR DEMO .OPML FILES (TAGGED WITH VARIOUS ATTRIBUTE VALUES)	var strFolderPath = app.chooseFolder({		withPrompt: "CHOOSE FOLDER CONTAINING SAMPLE " + strExtnUpper + " FILES"	}).toString();		// SHOW A MENU OF PERSPECTIVES	while (varChoice) {		lstMenu = Object.keys(dctXQuery);		varChoice = lstMenu.length ? app.chooseFromList(lstMenu, {			withTitle: "xQuery across several files",			withPrompt: "Select Perspective:",			defaultItems: [lstMenu[0]]		}) : false;		// USE THE MENU NAME AS THE REPORT TITLE		strMenuKey = varChoice[0];		// REFERENCE EACH FILE IN AN XINCLUDE DOCUMENT		lstFiles = filesInFolderWithExtn(strFolderPath, strExtn);		if (lstFiles.length) {			strXML = xIncludeXML(				filesInFolderWithExtn(strFolderPath, strExtn), 'body', 'outline'			);		} else {			app.displayDialog("No " + strExtnUpper + " files found in " + strFolderPath);			return;		}		// READ THE XINCLUSIONS INTO A COMPOSITE XML FILE		docXML = $.NSXMLDocument.alloc.initWithXMLStringOptionsError(			strXML, $.NSXMLDocumentXInclude, null		);		// THEN APPLY THE QUERY ...		lst = ObjC.unwrap(docXML.objectsForXQueryError(			dctXQuery[strMenuKey], null		));

		// debug return lst for quick harvest check
		// return lst;
		// AND HARVEST ANY RESULT		if (!lst) return;		i = lst.length;		if (i) {			while (i--) {				lst[i] = ObjC.unwrap(lst[i]);			}			if (blnOpenPerspectiveInMarked) {				// WRITE OUT PERSPECTIVE AS TEXT FILE				strTXT = $.NSString.alloc.initWithUTF8String(					'## <font color=gray>' + strMenuKey + '</font>\n\n' + lst.join('\n')				);
 				strPATH = $.NSString.alloc.initWithUTF8String(
					strTestFile
				);				strPATH = ObjC.unwrap(strPATH.stringByExpandingTildeInPath);

							blnWritten = strTXT.writeToFileAtomically(strPATH, true);				// AND OPEN IT IN [MARKED 2](http://marked2app.com)				if (blnWritten) {					app.doShellScript(						'open -a "Marked 2" ' + strPATH					);				}			} else {				varChoice = app.chooseFromList(lst, {					withTitle: strMenuKey,					withPrompt: "Select from actions matching [" + strMenuKey + "]:",					defaultItems: lst[0],					multipleSelectionsAllowed: true				});				// OPEN THE OPML FILE(S) FOR THE CHOSEN ACTION(S) IN THE DEFAULT OPML EDITOR ?				if (blnOpenSelected) {					if (varChoice) {						i = varChoice.length;						while (i--) {							oMatch = rgxFileURL.exec(varChoice[i]);							if (oMatch) {								app.doShellScript('open ' + oMatch[1]);							}						}						break;					}				}			}		} else {			app.displayAlert(				"No matches for " + strMenuKey + " found in " + strFolderPath +				" .opml files"			);		}	}	return true;}                              "jscr  úÞÞ­
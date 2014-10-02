property pTitle : "Filter FoldingText on all selected tags"property pVer : "0.1"property pAuthor : "Copyright (c) 2014 Robin Trew"property pLicense : "MIT - see full text to be included in ALL copies at https://github.com/RobTrew/txtquery-tools

					  (FoldingText is Copyright (c) 2014 Jesse Grosjean)
"property pUse : "

	Filters on all tags overlapping single or multiple selections.

	(For multiple selections in FoldingText, hold down the ⌘ command key)

	To include ancestors of the tagged lines:
			edit precOptions below to {axis:'///'}

	To exclude ancestors:
			edit precOptions below to {axis:'//'}
"property precOptions : {axis:"//"} -- or axis {"///"} to include ancestors of tagged linesproperty pstrJS : "
	function(editor, options) {

		function selectedTags(editor) {
			// ALL TAGS OVERLAPPED BY ANY SINGLE OR MULTIPLE SELECTIONS
			var	rngSeln, oNode, dctTagPosns,
					lstSeln, lstNodes, lstSelnPosns, lstSeldTags=[],
					lstNodeTags, lstTagStartEnd,
					strTag, blnSeln = editor.hasSelection(), i,j;

			if (blnSeln) {
				lstSeln = editor.selectedRanges();
				for (i=lstSeln.length; i--;) {
					rngSeln = lstSeln[i];
					lstNodes = rngSeln.nodesInRange();
					for (j=lstNodes.length; j--;) {
						oNode = lstNodes[j];
						// If the node has tags
						if (Object.keys(oNode.tags()).length) {
							dctTagPosns = tagPositions(oNode);
							lstSelnPosns = selnPositions(oNode, rngSeln);
	
							for (strTag in dctTagPosns) {
								// Unless we have already seen this tag
								if (lstSeldTags.indexOf(strTag) == -1) {
									if (overlap(dctTagPosns[strTag], lstSelnPosns))
										lstSeldTags.push(strTag);
								}
							}
						}
					}
				}
			}
			return lstSeldTags;
		}

		function tagPositions(oNode) {
			// START AND END OFFSETS OF EACH TAG IN THIS NODE
			var	lstRuns = oNode.lineAttributedString()._attributeRuns,
				dctTagPosns = {}, oRun, oAttr, strTag, iFrom, k;

			for (k=lstRuns.length; k--;) {
				oRun = lstRuns[k];
				oAttr = oRun.attributes;
				if (oAttr.keyword == '@') {
					strTag = oAttr.tag;
					iFrom = oRun.location;
					dctTagPosns[tagKey(strTag)]=[iFrom, iFrom+strTag.length];
				}
			}
			return dctTagPosns;
		}

		function selnPositions(oNode, rngSeln) {
			// OFFSETS OF FIRST AND LAST SELECTED CHARS IN THIS NODE
			var iNodeEnd = oNode.line().length,
				iSelnStart = rngSeln.startOffset,
				iSelnLength = rngSeln.length(),
				iNodeAbsStart = oNode.lineTextStart(), 
				iNodeAbsEnd = iNodeAbsStart + iNodeEnd,
				iSelnAbsStart = rngSeln.location(),
				iSelnAbsEnd = iSelnAbsStart + iSelnLength,
				iStart, iEnd;

			if (iSelnAbsStart < iNodeAbsStart) iStart = 0;
			else iStart = iSelnStart;

			if (iSelnAbsEnd > iNodeAbsEnd) iEnd = iNodeEnd;
			else iEnd =iSelnStart+iSelnLength;

			return [iStart, iEnd];
		}

		function overlap(lstA, lstB) {
			// NOT IF THIS ENDS BEFORE THAT STARTS,
			// OR STARTS AFTER THAT ENDS
			return !(lstA[1] < lstB[0] || lstA[0] > lstB[1]);
		}

		function tagKey(strKeyValueTag) {
			// JUST THE KEY PART OF A @key(value) OR @key TAG
			var	strKey, iOpen = strKeyValueTag.indexOf('(');

			if (iOpen !== -1) strKey = strKeyValueTag.substring(1, iOpen);
			else strKey = strKeyValueTag.substring(1);
			return strKey;
		}

		var lstSeldTags = selectedTags(editor),
			strPath = '///*',
			lngTags, i;
	
		lngTags = lstSeldTags.length;
		if (lngTags) {
			strPath = options.axis
			if (lngTags < 2)
				strPath += ('@' + lstSeldTags[0]);
			else {
				strPath += '(';
				for (i=lngTags; i--;) {
					strPath += ('@' + lstSeldTags[i] + ' or ');
				}
				strPath = strPath.substr(0, strPath.length -4) + ')';
			}
		}
		editor.setNodePath(strPath);
		return strPath;
	}

"on run	set varResult to missing value	tell application "FoldingText"		set lstDocs to documents		if lstDocs ≠ {} then			tell item 1 of lstDocs				set varResult to (evaluate script pstrJS with options precOptions)			end tell		end if	end tell	return varResultend run
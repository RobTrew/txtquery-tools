property pTitle : "Copy front FoldingText 2 document as CSV or TSV"property pVer : "0.1"property pAuthor : "Rob Trew  Twitter:  @complexpoint"property pDescription : "

	Copies contents of front FoldingText document to the clipboard as CSV or TSV
	(tab separated values)

	Edit pstrDelim below to specify commas or tabs

	(NOTE: a tab-delimited TSV version can be pasted straight into Excel,
	CSV needs to be pasted into a text file, and then opened in Excel)

	FORMAT:
		One spreadsheet column for each level of outline indentation, and
		One spreadsheet column for each type of @key(value) tag in the document

		The key of @key(value) is used as the column heading, 
		and the value is placed in the spreadsheet cells

	DATES:
		Excel automatically recognises yyyy-mm-dd
		and yyyy-mm-dd  hh:mm as datetime strings, and converts them accordingly.

	   @due(2015-06-01 14:00) will become an excel date in a column with header 'Due'

"property pstrTab : tabproperty pstrComma : ","-- SPECIFY FIELD DELIMITER BY EDITING THE VALUE OF PSTRDELIM HEREproperty pstrDelim : pstrTabproperty precOptions : {delimiter:pstrDelim}-- NOTE: FIELDS CONTAINING THE DELIMITER WILL BE QUOTEDproperty pstrJS : "
function(editor, options) {

	function maxdepth(node) {
		// DEEPEST LEVEL IN THE FOLDINGTEXT OUTLINE
		var	lngChiln = 0, lstChiln=[],
			lngMax = 0, lngDepth = 0;

		if (node.hasChildren()) {
			lstChiln = node.children();
			for (var i = lstChiln.length; i --;) {
				lngDepth = maxdepth(lstChiln[i]) + 1;
				if (lngDepth > lngMax) lngMax = lngDepth;
			}
		}
		return lngMax;
	}

	function nestLevel(oNode) {
		// OUTLINE LEVEL OF THIS NODE
		var oParent = oNode.parent;
		if (!oNode.parent) {
			return -1;
		} else return nestLevel(oParent) +1;
	}

	var	strDelim = options.delimiter,
		oTree=editor.tree(),
		lngLevels = maxdepth(oTree.root),
		lstTags = oTree.tags(true).sort(),
		lngTags = lstTags.length,
		lngCols=lngLevels+lngTags,
		lstCols=new Array(lngCols),
		lstRecord, strTag, iTag, iCol,
		lstRows=[];

	// CREATE A HEADER (ONE COLUMN FOR EACH OUTLINE LEVEL, AND ONE COLUMN FOR EACH TAG)
	lstRecord = lstCols.slice(0);
	for (iCol=lngLevels; iCol--;) {
		lstRecord[iCol] = 'Level ' + (iCol+1).toString();
	}
	for (iTag=lngTags; iTag--;) {
		strTag=lstTags[iTag]
		lstRecord[lngLevels+iTag] = strTag[0].toUpperCase() + strTag.slice(1).toLowerCase();
	}
	lstRows.push(lstRecord.join('\\t'));

	// GATHER THE DATA ROWS
	oTree.nodes().forEach(function (oNode) {
		lstRecord = lstCols.slice(0);
		lstRecord[nestLevel(oNode)] = oNode.text();
		for (iTag=lngTags;iTag--;) {
			strTag=lstTags[iTag];
			if (oNode.hasTag(strTag)) {
				strValue=oNode.tag(strTag);
				if (strValue.indexOf(strDelim) !== -1) {
					strValue='\"' + strValue + '\"';
				}
				lstRecord[lngLevels+iTag] = strValue;
			}
		}
		strRow = lstRecord.join(strDelim);
		lstRows.push(strRow);
	});

	return lstRows.join('\\n');
}
"on run	set varResult to missing value	tell application "FoldingText"		set lstDocs to documents		if lstDocs ≠ {} then			tell item 1 of lstDocs to set varResult to (evaluate script pstrJS with options precOptions)			set the clipboard to varResult		end if	end tell	return varResultend run
property pTitle : "Filter FT on chosen tags"property pVer : "0.1"property pAuthor : "Copyright (c) 2014 Robin Trew"property pLicense : "MIT - see full text to be included in ALL copies at https://github.com/RobTrew/txtquery-tools

					  (FoldingText is Copyright (c) 2014 Jesse Grosjean)
"property pUse : "

	Filters on all tags chosen from a menu.

	(For multiple selections in the menu, hold down the ⌘ command key)

	To include ancestors of the tagged lines:
			edit precOptions below to {axis:'///'}

	To exclude ancestors:
			edit precOptions below to {axis:'//'}
"property precOptions : {axis:"//"} -- or axis {"///"} to include ancestors of tagged linesproperty pstrJS : "
	function(editor, options) {

		var lstSeldTags = options.tagset,
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

"on run	set varResult to missing value	tell application "FoldingText"		set lstDocs to documents		if lstDocs ≠ {} then			tell item 1 of lstDocs				set lstTags to my ChooseTags(it)				if lstTags ≠ missing value then					set varResult to (evaluate script pstrJS with options precOptions & {tagset:lstTags})				else					evaluate script "function (editor) {editor.setNodePath('///*')}"				end if			end tell		end if	end tell	return varResultend runon ChooseTags(oDoc)	tell application "FoldingText"		tell oDoc to set lstTags to evaluate script "function(editor) {var lstTags = editor.tree().tags(false); lstTags.sort(); return lstTags;}"		activate		if lstTags ≠ {} then			set varChoice to choose from list lstTags with title pTitle & tab & pVer with prompt ¬				"Hold down ⌘ for multiple selections" & linefeed & linefeed & "Choose tags: " default items {item 1 of lstTags} ¬				OK button name "OK" cancel button name "Cancel" with empty selection allowed and multiple selections allowed			if varChoice = false then return missing value			return varChoice		else			return {}		end if	end tellend ChooseTags
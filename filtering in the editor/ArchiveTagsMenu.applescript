property pTitle : "Archive chosen tag-types to matching section"property pVer : "0.1"property pAuthor : "Copyright (c) 2014 Robin Trew"property pLicense : "MIT - see full text to be included in ALL copies at https://github.com/RobTrew/txtquery-tools

					  (FoldingText is Copyright (c) 2014 Jesse Grosjean)
"property pUse : "

	Archives all line tagged with a tag chosen from a menu,
	to a section '# Archive  <Tagname>'.

	To change the affected tag, edit the tagname in property precOptions below this line.

	(if you comment out the precOptions line, the script will offer a menu,
	 listing each type of tag found in the document )
"

-- INCLUDE A LINE LIKE THE FOLLOWING TO BY-PASS THE MENU AND CREATE A SCRIPT SPECIFIC TO ONE TAG TYPE-- property precOptions : {archivetags:{"waiting"}}-- property precOptions : {archivetags:{"cancelled"}}property pstrJS : "
	function(editor) {
		// Skip any line already archived with an ancestor
		function rootsOnly(oTree, lstNodes) {
			var lstSeen = [], strID, oParent, lngNodes=lstNodes.length, oNode,i;
			
			nextnode: for (i=0; i<lngNodes;i++) {
				oNode = lstNodes[i];
				strID = oNode.id;
				oParent = oNode.parent
				while (oParent) {
					if (lstSeen.indexOf(oParent.id) !== -1) continue nextnode
					oParent=oParent.parent;
				}
				lstSeen.push(strID);
			}
			lngNodes = lstSeen.length;
			for (i=lngNodes; i--;) {
				lstSeen[i] = oTree.nodeForID(lstSeen[i]);
			}
			return lstSeen;
		}

		var tree = editor.tree(), nodeArchive, oNode, rngArchive=null,
			lstTags = options.tagset, lstTagged, lstRoots,
			strID, strTag, strPath, strArchive,
			lngTags = lstTags.length, lngRoots, i,j;

		tree.beginUpdates();
		tree.ensureClassified();

		for (i=lngTags; i--;) {
			strTag = lstTags[i];
			if (strTag) {
				strArchive = 'Archive ' + strTag.charAt(0).toUpperCase() + strTag.slice(1);
				strPath = '//(@line:text=' + strArchive + ')[0]';
				nodeArchive = tree.evaluateNodePath(strPath)[0];
				if (!nodeArchive) {
					nodeArchive = tree.createNode('# ' + strArchive);
					tree.appendNode(nodeArchive);
				}
				
				strPath = '//@' + strTag + ' except //@line:text =\"' +
					strArchive + '\"//@' + strTag;
				lstTagged = tree.evaluateNodePath(strPath);

				lstRoots = rootsOnly(tree, lstTagged);
				lngRoots = lstRoots.length;
				for (j=lngRoots; j--;) {
					nodeArchive.insertChildBefore(
						lstRoots[j], nodeArchive.firstChild);
				}
			}
		}
		tree.endUpdates();
		if (nodeArchive) {
			rngArchive = tree.createRangeFromNodes(nodeArchive,0,nodeArchive,-1);
			editor.scrollRangeToVisible(rngArchive);
			editor.setSelectedRange(rngArchive);
		}
	}

"on run	set varResult to missing value	set lstTags to {}	tell application "FoldingText"		set lstDocs to documents		if lstDocs ≠ {} then			try				set lstTags to (archivetags of precOptions)			end try			tell item 1 of lstDocs				if lstTags = {} then set lstTags to my ChooseTags(it)				if lstTags ≠ {} then					set varResult to (evaluate script pstrJS with options {tagset:lstTags})				end if			end tell		end if	end tell	return varResultend runon ChooseTags(oDoc)	tell application "FoldingText"		tell oDoc to set lstTags to evaluate script "function(editor) {var lstTags = editor.tree().tags(false); lstTags.sort(); return lstTags;}"		activate		if lstTags ≠ {} then			set varChoice to choose from list lstTags with title pTitle & tab & pVer with prompt ¬				"Choose tags: " default items {item 1 of lstTags} ¬				OK button name "OK" cancel button name "Cancel" with empty selection allowed without multiple selections allowed			if varChoice = false then return missing value			return varChoice		else			return {}		end if	end tellend ChooseTags
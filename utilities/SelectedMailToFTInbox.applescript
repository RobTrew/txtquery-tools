property pTitle : "Selected Mail.app msg to FT Inbox"property pVer : "0.2"property pAuthor : "Rob Trew Twitter: @complexpoint"-- EDIT THE FOLLOWING DETAILS TO SET THE BEHAVIOUR OF THE SCRIPTproperty pblnAppendToFile : false -- (set to true if you simply want to append to the end of a named text file)property pblnAddToTop : true -- (if adding to # Inbox section, add at top or end ?)property pstrFilePath : "$HOME/Library/Application Support/Notational Velocity/Inbox.txt"property pstrNodePath : "/Inbox" -- (Assumes that inbox is a top level heading, if it exists)property precOptions : {inboxpath:pstrNodePath, top:pblnAddToTop}property pstrJS : "

	function(editor, options) {
		var oTree = editor.tree(),
			lstInbox = oTree.evaluateNodePath(options.inboxpath), oInbox, 
			strText, lstChiln, strMsg=options.msg, lstLines = strMsg.split('\\n'),
			lngLines = lstLines.length, i, oFirstChild=null, blnTop = options.top;
	
		if (lngLines) {
			// CHECK THAT WE HAVE AN INBOX (CREATING ONE IF NECESSARY)
			if (lstInbox.length) {
				oInbox = lstInbox[0];
			} else {
				oInbox = oTree.createNode('# Inbox');
				oTree.appendNode(oInbox);
			}
			oTree.ensureClassified();
			if (oInbox.hasChildren()) {
				oFirstChild = oInbox.children()[0];
			}
			// ADD NEW LINES EITHER AT START OR END OF INBOX
			if (blnTop && oFirstChild) {
				for (i=0; i<lngLines; i++) {
					oInbox.insertChildBefore(oTree.createNode(lstLines[i]),oFirstChild);
				}
			} else {
				for (i=0; i<lngLines; i++) {
					oInbox.appendChild(oTree.createNode(lstLines[i]));
				}
			}
		}
	}

"on run	-- TRY TO GET A NORMALISED VERSION OF THE FILENAME	set strPath to (do shell script "echo \"" & pstrFilePath & "\"")		-- GET MD LINKS TO ANY SELECTED MAIL.APP MESSAGES	set strMD to MailSelnAsMd()	if strMD ≠ "" then				-- EITHER APPEND TO AN INBOX TEXT FILE (IF property pblnAppendToFile : TRUE)		if pblnAppendToFile then			set strCMD to "echo " & quoted form of strMD & " >> " & quoted form of strPath			do shell script strCMD					else			-- OR OPEN AS DOC IN FT AND ADD TO AN INBOX SECTION (IF property pblnAppendToFile : FALSE)			set recOptions to {msg:strMD} & precOptions			tell application "FoldingText"				set oDoc to open strPath				tell oDoc to set varResult to (evaluate script pstrJS with options recOptions)			end tell		end if	end ifend runon MailSelnAsMd()	tell application "Mail"		activate		set lstText to {}		repeat with refMsg in (selection as list)			tell (contents of refMsg)				set strLine to "- [" & sender & "]() [" & subject				set end of lstText to strLine & "](message://%3c" & message id & "%3e)"			end tell		end repeat		set {dlm, my text item delimiters} to {my text item delimiters, linefeed}		set strTxt to lstText as string		set my text item delimiters to dlm		return strTxt	end tellend MailSelnAsMd
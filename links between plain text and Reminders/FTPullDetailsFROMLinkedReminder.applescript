property pTitle : "Pull date/priority/etc from a linked Reminder.app item to the selected FT2 line"property pVer : "0.8"property pAuthor : "Rob Trew"-- 1. DECIDE WHICH FIELDS FROM REMINDERS ITEMS TO BRING DOWN TO PLAIN TEXT LINES-- Creation time, Alert time, completion status/time, priority level, if any)-- Edit these values to true or falseproperty precTagKeys : {created:false, Alert:true, done:true, priority:true}-- 2. AND, IF YOU WILL BE INCLUDING Alert OR CREATED DATE/TIMES, CHOOSE PLAIN TEXT TAG KEYS FOR THEM property pstrAlertTag : "@alert"property pstrCreatedTag : "@created" -- irrelevant if 'created':false aboveproperty pstrLinkLabel : "{clock}"property pstrRTPluginFolder : "FoldingText 2 plugins and scripts"property pRTPluginLink : "https://github.com/RobTrew/tree-tools"property plstPlugins : {{|name|:"smalltime", |version|:0.2, |URL|:pRTPluginLink, |folder|:pstrRTPluginFolder}}-- 3. CHOOSE THREE LEVELS OF OF PRIORITY @TAG OR @KEY(VALUE) PATTERN (REMINDERS ONLY USES 3 PRIORITY LEVELS)--  AND PLACE THEM IN THE plstHeatTags LIST BELOW *IN DESCENDING ORDER*--  (Reminders.app only offers three levels of priority)-- 1 to 3 @tags or @key(value) pairs eg  ,{"@hi", "@med", "@lo"} {"@priority(0)", "@priority(1)", "@priority"}-- in descending priority. If you use 4 or more tags, the fourth onwards will be treated as-- alternative indications of the lowest (third) priorityproperty plstHeatTags : {"@priority(1)", "@priority(2)", "@priority(3)"}-- don't edit this :-)property pSQL : "sqlite3 $HOME/Library/Calendars/Calendar\\ Cache \"select zlocaluid, strftime('%Y-%m-%d %H:%S', zcreationdate + 978307200, 'unixepoch', 'localtime'), strftime('%Y-%m-%d %H:%S', zduedate + 978307200, 'unixepoch', 'localtime'), strftime('%Y-%m-%d %H:%S', zcompleteddate + 978307200, 'unixepoch', 'localtime'), zpriority from zcalendaritem inner join znode on zcalendaritem.zcalendar = znode.z_pk where zcalendaritem.z_ent is 9 and zlocaluid in ("property pstrJSUpdateTags : "
	function(editor, options) {
		'use strict';
		var tree = editor.tree(),
		node, i,
		lstDeltaNodes = options.uuidnodes, lngNodes = lstDeltaNodes.length,
		dctDeltas, rgxKeyVal = /\\@?(\\w+)($|\\(([^\\(]))/,
		match = rgxKeyVal.exec(options.heatpattern), strHeatKey='', strHeatVal='',
		strAlertKey = options.Alerttag, strCreatedKey=options.createdtag, dteAlert, varValue, strURL,
		strLinkLabel=options.linklabel, oSmallTime, strText, rgxLink, strPattern, strUpdated, strLabel,
		strUrlScheme='x-apple-reminder:\\/\\/', oMatch;

		//drop any leading @ from the optional key names
		if (strAlertKey[0] === '@') {strAlertKey = strAlertKey.substr(1);}
		if (strCreatedKey[0] === '@') {strCreatedKey = strCreatedKey.substr(1);}
		if (match !== null) {strHeatKey = match[1];}

		// get a reference to the reminders plugin if the link label is computed
		if (strLinkLabel.charAt(0)=='{') oSmallTime=require(options.pluginPath);
		
		tree.beginUpdates();
		for (i=0; i < lngNodes; i++) {
			dctDeltas = lstDeltaNodes[i];
			node = tree.nodeForID(dctDeltas.id);

			varValue=dctDeltas.created;
			if (dctDeltas.created) node.addTag(strCreatedKey, dctDeltas.created);

			varValue=dctDeltas.Alert;
			if (varValue) {
				if (oSmallTime) {
					strText=node.text();
					dteAlert=oSmallTime.phraseToDate(varValue);
					strLabel=oSmallTime.timeEmoji(strLinkLabel, dteAlert);
			
					strURL=strUrlScheme+dctDeltas.uuid;
					strPattern='\\\\[.*\\\\]\\\\(' + strURL + '\\\\)';
					rgxLink= new RegExp(strPattern);
					strUpdated=strText.replace(rgxLink, '[' + strLabel + '](' +strURL + ')');
					node.setText(strUpdated);
				}	
				node.addTag(strAlertKey, dctDeltas.Alert);
			}

			varValue=dctDeltas.heat;
			if (varValue) {
				match = rgxKeyVal.exec(varValue);
				if (match !== null) {
					strHeatVal = match[3];
					if (strHeatVal === undefined) {strHeatVal = '';}
				} else {strHeatVal = '';}
				node.addTag(strHeatKey, strHeatVal);
			} else node.removeTag(strHeatKey);

			varValue=dctDeltas.completed;
			if (varValue) {
				node.addTag('done', varValue);
			} else node.removeTag('done');
		}
		tree.endUpdates();
		tree.ensureClassified();
	}"property pstrJSPullDataForSeldIDs : "
	function (editor) {
		var tree = editor.tree(),
		range = editor.selectedRange(),
		rgxLink = /\\[[^\\]]*\\]\\(x-apple-reminder:\\/\\/([A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12})\\)/,
		match=null, lstNodes = range.nodesInRange(), lstResult=[];

		lstNodes.forEach(function (node) {
			match = rgxLink.exec(node.line());
			if (match) lstResult.push([node.id, match[1]]);
		});
		return lstResult;
	}
"on run	tell application "FoldingText"		set lstDocs to documents		if lstDocs ≠ {} then			set lstloadedPlugins to my loadedPlugins((item 1 of lstDocs))		else			return		end if	end tell	set lstData to PullDataByUUIDinSeldLines()	if lstData ≠ {} then		if plstHeatTags ≠ {} then			set strHeatSample to item 1 of plstHeatTags		else			strHeatSample to ""		end if				repeat with lstLine in lstData			if length of lstLine = 2 then				tell application "FoldingText"					activate					set strMsg to "Linked reminder not found for this UUID:" & linefeed & linefeed & my GetTextForID(item 1 of lstLine) & ¬						linefeed & linefeed & "(may have been deleted)"					display dialog strMsg buttons {"OK"} default button "OK" with title pTitle & "  ver. " & pVer					return				end tell			end if		end repeat				set recValues to ApplyOptions(lstData)				FTUpdateTags(recValues & {heatpattern:strHeatSample, Alerttag:pstrAlertTag, createdtag:pstrCreatedTag, pluginPath:item 1 of lstloadedPlugins, linklabel:pstrLinkLabel})	end ifend runon GetTextForID(strId)	tell application "FoldingText"		set lstDocs to documents		if lstDocs ≠ {} then			tell item 1 of lstDocs				set varLine to (evaluate script "
					function(editor, options) {
						return editor.tree().nodeForID(options.idNode).text();
					}" with options {idNode:strId})			end tell		end if	end tellend GetTextForIDon ApplyOptions(lstLineData)	if lstLineData ≠ {} then		set lstPriority to Get9PartPriorityList()		tell precTagKeys			set {blnCreated, blnAlert, blnDone, blnPriority} to {created of it, Alert of it, done of it, priority of it}		end tell		repeat with i from 1 to length of lstLineData			set lstValues to contents of item i of lstLineData			set {strUUID, strCreated, strAlert, strDone, strPriority, strId} to lstValues			-- DISCARD ANY DATA THAT ISN'T WANTED IN THE TEXT FILE			if not blnCreated then set strCreated to ""			if not blnAlert then set strAlert to ""			if not blnDone then set strDone to ""			if not blnPriority then set strPriority to ""						if (strPriority ≠ "") and (strPriority ≠ "0") then				set strPriority to item (strPriority as integer) of lstPriority			else				set strPriority to ""			end if			set item i of lstLineData to {uuid:strUUID, |id|:strId, created:strCreated, Alert:strAlert, completed:strDone, heat:strPriority}		end repeat				return {uuidnodes:lstLineData}	end ifend ApplyOptionson Get9PartPriorityList()	set lstBase to contents of plstHeatTags	set lngBase to length of lstBase	set lstLong to {}	if lngBase > 0 then		-- Get a base of three tags,		-- neither less		repeat while length of lstBase < 3			set oTag to contents of item -1 of lstBase			set end of lstBase to oTag		end repeat		-- nor more		set lstBase to items 1 thru 3 of lstBase	else		set lstBase to {"@priority(1)", "@priority(2)", "@priority(3)"}	end if	-- and expand to nine (9 priority levels in the DB, only 3 in Reminders.app)	repeat with i from 1 to 3		set oTag to contents of item i of lstBase		repeat with j from 1 to 3			set end of lstLong to oTag		end repeat	end repeat		return lstLongend Get9PartPriorityListon FTUpdateTags(recValuesAndKeys)	tell application "FoldingText"		set lstDocs to documents		if lstDocs ≠ {} then			tell item 1 of lstDocs				set varLine to (evaluate script pstrJSUpdateTags with options recValuesAndKeys)			end tell		end if	end tellend FTUpdateTagson PullDataByUUIDinSeldLines()	set lstUpdates to {}	tell application "FoldingText"		set lstDocs to documents		if lstDocs ≠ {} then			tell item 1 of lstDocs				set lstUUID to (evaluate script pstrJSPullDataForSeldIDs)			end tell		end if	end tell		if lstUUID ≠ {} then		set lstData to DetailsFromUID(lstUUID)	else		set lstData to {}	end if		if lstData ≠ {} then		return lstData	else		return lstUUID	end ifend PullDataByUUIDinSeldLineson DetailsFromUID(lstUUID)	set strSet to ""	set lngUUID to length of lstUUID	repeat with i from 1 to length of lstUUID		set {strId, strUID} to item i of lstUUID		set strSet to strSet & quoted form of strUID & ", "	end repeat		-- Get date strings and priority integer string 1=hi 5=med 9=lo	-- {Creation, Due, Completed, Priority}	set strCmd to pSQL & (text 1 thru -3 of strSet) & ")\""		set lstDetails to paragraphs of (do shell script strCmd)	if lstDetails ≠ {} then		set {dlm, my text item delimiters} to {my text item delimiters, "|"}		repeat with i from 1 to length of lstDetails			set lstFields to text items of item i of lstDetails			set strUUID to item 1 of lstFields			repeat with j from 1 to lngUUID				if item 2 of (item j of lstUUID) = strUUID then					set strId to item 1 of (item j of lstUUID)					set end of lstFields to strId					exit repeat				end if			end repeat			set item i of lstDetails to lstFields		end repeat		set my text item delimiters to dlm	end if	return lstDetailsend DetailsFromUIDon loadedPlugins(oDoc)	-- CHECK THAT REQUIRED PLUGINS ARE INSTALLED AND UP TO DATE	tell application "FoldingText"		tell oDoc			set lstloadedPlugins to (evaluate script "
				function(editor, options) {
					'use strict'
					// check for plugins
					var	fnQuery = require('ft/util/queryparameter').QueryParameter,
						lstPlugins = fnQuery('pluginPaths', '').split(':'),
						lstFound = [];
						options.needed.forEach(function(dctPlugin) {
							var strFolder = '/Plug-Ins/' + dctPlugin.name + '.ftplugin/',
								lngPlugins = lstPlugins.length, strPluginPath,
								blnFound, i, oPlugin;
							for (i=0; i<lngPlugins; i++) {
								strPluginPath = lstPlugins[i];
								blnFound = (strPluginPath.indexOf(strFolder) !== -1);
								if (blnFound) {
									// check whether the plugin is up to date
									oPlugin = require(strPluginPath);
									if (oPlugin.version >= dctPlugin.version) {
										lstFound.push(strPluginPath);
									} else {
										lstFound.push(oPlugin.version);
									}
									break;
								}
							}
							if (!blnFound) {lstFound.push(null);}
						});
					return lstFound;
				}" with options {needed:plstPlugins})		end tell	end tell	return lstloadedPluginsend loadedPlugins
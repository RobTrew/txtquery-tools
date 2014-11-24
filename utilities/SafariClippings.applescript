function run() {
	var dct = {
		title: "Append Safari clipboard to end of file",
		ver: "0.4",
		description: "Creates MD header with page title, url & timestamp",
		author: "RobTrew copyright 2014",
		license: "MIT",
		site: "https://github.com/RobTrew/txtquery-tools"
	};
	
	var appSafari = Application("Safari");
	if (appSafari.windows.length < 1) return 'No windows open in Safari ...';

	var dctOptions = {
		$today:fmtTP(new Date(),false),
		clipfile:"notes-{$today}.txt", // or just 'clippings.txt' etc
		clipfolder: "$HOME/Library/Application Support/Notational Velocity/",
		clipheadings: "### ",
		urlprefix: "- ",
		cliptimetag: "clip",
		useNSnotification: false, // turn off for KeyBoard Maestro
		clippedsound: 'Pop',
		problemsound: 'Blow'
	};
	//ALTERNATIVE SOUND NAMES
	//Basso	Frog Hero Pop Submarine
	//Blow Funk	Morse Purr Tink
	//Bottle Glass Ping Sosumi

	//PREPARE FOR ANY NOTIFICATION
	ObjC.import('Cocoa');
	try {
		ObjC.registerSubclass({
			name: 'BriefNotify',
			methods: {
				'userNotificationCenter:shouldPresentNotification:': {
					types: ['bool', ['id', 'id']],
					implementation: function (center, notification) {
						return true;
					}
				}
			}
		});
	} catch (e) {} // already defined


	

	var app = Application.currentApplication(),
		oWindow = appSafari.windows[0],
		oTab = oWindow.currentTab,
		strName = oWindow.name(),
		strURL = oTab.url(),
		strLink = '[' + strName + '](' + strURL + ')',
		strSetUTF8='LANGSTATE="$(defaults read -g AppleLocale).UTF-8"; if [[ "$LC_CTYPE" != *"UTF-8"* ]]; then export LC_ALL="$LANGSTATE" ; fi; ',
		strHeading, strRefce, strCmd,
		strClip = '',
		strPath, strQuotedPath='',
		oBriefNotify = $.BriefNotify.alloc.init,
		strMsg, strDetail, strSound = '',
		strLastPage='',
		strTag='@' + dctOptions.cliptimetag + "(" + fmtTP(new Date()) + ")",
		varResult;

	function expandTokens(strSource, dctTokens) { //patterns like {$token} replaced by value of dctTokens.$token
		var rgxToken = /\{(\$\w+)\}/g,
			strTrans = strSource,
			oMatch=rgxToken.exec(strSource);
			
		while (oMatch) {
			strTrans=strTrans.replace(oMatch[0], dctTokens[oMatch[1]]);
			oMatch=rgxToken.exec(strSource);
		}
		return strTrans;
	}


	function makePath(strFolder, strFileName) {
		var strCMD = 'fldr=$(echo "' + strFolder + '"); if [ -e \"$fldr\" ]; then echo $fldr; fi',
			strPath=app.doShellScript(strCMD).trim(),
			strFullPath='';
						
		if (strPath) {
			if (strPath[strPath.length-1]==='/')
				strFullPath=strPath+strFileName
			else strFullPath=strPath+'/'+strFileName
		};
		return strFullPath;
	}
	
	// Taskpaper-style datetime stamp yyy-mm-dd HH:MM
	function fmtTP(dte, blnTime) {
		var strDate = '',
			strDay = '',
			strTime = '',
			blnAddTime=(typeof blnTime)==='undefined'?true:blnTime;
			
		
		strDay = [dte.getFullYear(), ('0' + (dte.getMonth() +
			1)).slice(-2), ('0' + dte.getDate()).slice(-2)].join('-');
		strTime = [('00' + dte.getHours()).slice(-2), ('00' +
			dte.getMinutes()).slice(-2)].join(':');
		if (blnAddTime && (strTime !== '00:00')) strDate = [strDay, strTime].join(' ');
		else strDate = strDay;
		return strDate;
	}

	// single quoting for bash shell
	function shellEscaped(cmd) {
		return '\'' + cmd.replace(/\'/g, "'\\''") + '\'';
	}


	
	
	function postNote(strTitle, txtInfo, strSoundName) {
		var noteFlash = $.NSUserNotification.alloc.init,
			strSound = strSoundName || 'Glass';

		noteFlash.title = strTitle;
		noteFlash.informativeText = txtInfo;
		noteFlash.soundName = strSound;
		$.NSUserNotificationCenter.defaultUserNotificationCenter.deliverNotification(noteFlash);
	}
	
	function selnAsHTML() {
		var selnWin = window.getSelection(),
			lng = selnWin.rangeCount,
			oDiv;

		if (lng) {
			oDiv = document.createElement('div');
			for (var i = 0; i < lng; i++) {
				oDiv.appendChild(selnWin.getRangeAt(i).cloneContents());
			}
			return oDiv.innerHTML;
		}
		return '';
	}


	app.includeStandardAdditions=true;
	
	strFullFileName=expandTokens(dctOptions.clipfile, dctOptions);
	
	strPath = makePath(dctOptions.clipfolder, strFullFileName);
	if (strPath) strQuotedPath = '"' + strPath + '"'
	else return "Folder not found"
		
	// Get most recent link (if any, in clippings file)
	strCMD="CLIPFILE=" + strQuotedPath + ";if [ -e \"$CLIPFILE\" ]; then cat -n \"$CLIPFILE\" | sort -t: -k 1nr,1 | grep -o -m 1 \'\\[.*\\](.*)\' ; fi"
	//return strCMD;
	try {
		strLastPage=app.doShellScript(strCMD);
	} catch (e) { strLastPage=''};
	
	
	// Get the selected HTML
	
	

	
	if (strLastPage !== strLink) {
		// Creating new heading from web page name and MD link to URL
		strHeading = dctOptions.clipheadings + strName;
		strRefce = dctOptions.urlprefix + strLink;
		strClip = [strHeading, strRefce, ''].join('\n') + '\n\n';
		
		// and append heading and clipboard text to the end of the file
		strCMD = strSetUTF8 + 'echo ' +
			shellEscaped(strClip) + ' >> ' + strQuotedPath +'; pbpaste -Prefer txt >> ' +
			strQuotedPath + ' ; printf " ' + strTag + '\n\n" >> ' + strQuotedPath;
	} else {
		strCMD = strSetUTF8 + 'pbpaste -Prefer txt >> ' + strQuotedPath + ' ; printf " ' + strTag + '\n\n" >> ' + strQuotedPath;
	}


	try {
		varResult = app.doShellScript(strCMD);
	} catch (e) {
		varResult = e.message;
	}

	if (!varResult) {
		strMsg = "Appended to " + dctOptions.clipfile;
		strDetail = strLink;
		strSound = dctOptions.clippedsound;
	} else {
		strMsg = "NOT clipped ...";
		strDetail = varResult;
		strSound = dctOptions.problemsound;
	}

	if (dctOptions.useNSnotification) {
		$.NSUserNotificationCenter.defaultUserNotificationCenter.delegate = oBriefNotify;
		postNote(strMsg, strDetail, strSound);
	}
	return strFullFileName;

}
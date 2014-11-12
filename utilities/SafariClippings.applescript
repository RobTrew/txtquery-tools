function run() {
	var dct = {
		title: "Append Safari clipboard to end of file",
		ver: "0.3",
		description: "Creates MD header with page title, url & timestamp",
		author: "RobTrew copyright 2014",
		license: "MIT",
		site: "https://github.com/RobTrew/txtquery-tools"
	};

	var dctOptions = {
		clipfile: "$HOME/Library/Application Support/Notational Velocity/Clippings.txt",
		clipheadings: "### ",
		urlprefix: "- ",
		cliptimetag: "clip",
		useNSnotification: false, // turn off for KeyBoard Maestro
		clippedsound: 'Pop',
		problemsound: 'Blow',
		encoding: 'en_US.UTF-8'
	};
	//ALTERNATIVE SOUND NAMES
	//Basso	Frog Hero Pop Submarine
	//Blow Funk	Morse Purr Tink
	//Bottle Glass Ping Sosumi

	// Taskpaper-style datetime stamp yyy-mm-dd HH:MM
	function fmtTP(dte) {
		var strDate = '',
			strDay = '',
			strTime = '';
		strDay = [dte.getFullYear(), ('0' + (dte.getMonth() +
			1)).slice(-2), ('0' + dte.getDate()).slice(-2)].join('-');
		strTime = [('00' + dte.getHours()).slice(-2), ('00' +
			dte.getMinutes()).slice(-2)].join(':');
		if (strTime !== '00:00') strDate = [strDay, strTime].join(' ');
		else strDate = strDay;
		return strDate;
	}

	// single quoting for bash shell
	function shellEscaped(cmd) {
		return '\'' + cmd.replace(/\'/g, "'\\''") + '\'';
	}

	var appSafari = Application("Safari");

	if (!appSafari.windows.length) return 'Safari not running ...';

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

	function postNote(strTitle, txtInfo, strSoundName) {
		var noteFlash = $.NSUserNotification.alloc.init,
			strSound = strSoundName || 'Glass';

		noteFlash.title = strTitle;
		noteFlash.informativeText = txtInfo;
		noteFlash.soundName = strSound;
		$.NSUserNotificationCenter.defaultUserNotificationCenter.deliverNotification(noteFlash);
	}

	var app = Application.currentApplication(),
		oWindow = appSafari.windows[0],
		oTab = oWindow.tabs[0],
		strName = oWindow.name(),
		strURL = oTab.url(),
		strLink = '[' + strName + '](' + strURL + ')',
		strHeading, strRefce, strCmd,
		strClip = '',
		strQuotedPath = '"' + dctOptions.clipfile + '"',
		oBriefNotify = $.BriefNotify.alloc.init,
		strMsg, strDetail, strSound = '',
		strLastPage='',
		strTag='@' + dctOptions.cliptimetag + "(" + fmtTP(new Date()) + ")",
		varResult;

	app.includeStandardAdditions = true;
	
	// Get most recent link (if any, in clippings file)
	strCMD="CLIPFILE=" + strQuotedPath + ";if [ -e \"$CLIPFILE\" ]; then cat -n \"$CLIPFILE\" | sort -t: -k 1nr,1 | grep -o -m 1 \'\\[.*\\](.*)\' ; fi"
	try {
		strLastPage=app.doShellScript(strCMD);
	} catch (e) { strLastPage=''};
	
	if (strLastPage !== strLink) {
		// Creating new heading from web page name and MD link to URL
		strHeading = dctOptions.clipheadings + strName;
		strRefce = dctOptions.urlprefix + strLink;
		strClip = [strHeading, strRefce, ''].join('\n') + '\n\n';
		
		// and append heading and clipboard text to the end of the file
		strCMD = 'LANG=' + dctOptions.encoding + '; echo ' + shellEscaped(strClip) + ' >> ' + strQuotedPath +
			'; pbpaste >> ' + strQuotedPath + ' ; printf " ' + strTag + '\n\n" >> ' + strQuotedPath;
	} else {
		strCMD = 'LANG=' + dctOptions.encoding + '; pbpaste >> ' + strQuotedPath + ' ; printf " ' + strTag + '\n\n" >> ' + strQuotedPath;
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
	return strDetail;

}
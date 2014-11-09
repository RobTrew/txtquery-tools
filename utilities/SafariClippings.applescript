function run() {
	var dct = {
		title: "Append Safari clipboard to end of file",
		ver: "0.2",
		description: "Creates MD header with page title, url & timestamp",
		author: "RobTrew copyright 2014",
		license: "MIT",
		site: "https://github.com/RobTrew/txtquery-tools"
	};

	var dctOptions = {
		clipfile: "$HOME/Library/Application Support/Notational Velocity/Clippings.txt",
		clipheadings: "### ",
		urlprefix: "- ",
		datetimetag: "clipped",
		useNSnotification: false, // turn off for KeyBoard Maestro
		clippedsound: 'Pop',
		problemsound: 'Blow'
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
		strHeading, strRefce, strCmd,
		strPrefix = '',
		strQuotedPath = '"' + dctOptions.clipfile + '"',
		oBriefNotify = $.BriefNotify.alloc.init,
		strMsg, strDetail, strSound = '',
		varResult;

	app.includeStandardAdditions = true;

	// Creating heading from web page name and MD link to URL
	strHeading = dctOptions.clipheadings + strName + '  @' +
		dctOptions.datetimetag + "(" + fmtTP(new Date()) + ")";
	strRefce = dctOptions.urlprefix +
		'[' + oWindow.name() + '](' + oTab.url() + ')';
	strPrefix = [strHeading, strRefce, ''].join('\n') + '\n\n';

	// and append heading and clipboard text to the end of the file
	strCMD = 'echo ' + shellEscaped(strPrefix) + ' >> ' + strQuotedPath +
		'; pbpaste >> ' + strQuotedPath + ' ; printf "\n\n" >> ' + strQuotedPath;

	try {
		varResult = app.doShellScript(strCMD);
	} catch (e) {
		varResult = e.message;
	}

	if (!varResult) {
		strMsg = "Appended to " + dctOptions.clipfile;
		strDetail = strPrefix;
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
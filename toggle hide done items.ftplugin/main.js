define(function(require, exports, module) {
	var Extensions = require('ft/core/extensions').Extensions;

	Extensions.addCommand({
		name: 'toggle hide done items',
		description: 'Toggles between hiding @done items and showing all lines',
		performCommand: function(editor) {
			var strActivePath = editor.nodePath().nodePathString,
				lstNodes,
				strExceptDone = ' except //@done',
				lngChars=strExceptDone.length,
				strToggledPath, lngStart;

			switch (strActivePath) {
				case '///*':
					strToggledPath = '//not @done';
					break;
				case '//not @done':
					strToggledPath = '///*';
					break;
				default :
					lngStart = strActivePath.length-lngChars;
					if (strActivePath.indexOf(
							' except //@done', lngStart) == -1)
						strToggledPath = strActivePath + strExceptDone;
					else
						strToggledPath = strActivePath.substring(0, lngStart);
					break;
			}
			editor.setNodePath(strToggledPath);
		}
	});

	Extensions.addInit(function (editor) {
		editor.addKeyMap({
			'Cmd-Ctrl-Alt-H':'toggle hide done items'
		});
	});
});

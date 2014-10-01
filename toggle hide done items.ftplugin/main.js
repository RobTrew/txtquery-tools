define(function(require, exports, module) {
	var Extensions = require('ft/core/extensions').Extensions;

	Extensions.addCommand({
		name: 'toggle hide done items',
		description: 'Toggles between hiding @done items and showing all lines',
		performCommand: function (editor) {
			var strHideDone = '//not @done';
			if (editor.nodePath().nodePathString !== strHideDone)
				editor.setNodePath(strHideDone);
			else
				editor.setNodePath('///*');
		}
	});

	Extensions.addInit(function (editor) {
		editor.addKeyMap({
			'Cmd-Ctrl-Alt-H':'toggle hide done items'
		});
	});
});

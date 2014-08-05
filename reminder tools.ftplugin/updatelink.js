function(editor, options) {
	'use strict';
	var tree = editor.tree(),
		node = editor.selectedRange().startNode, strText=node.text(), strUUID=options.uuid, rgxLink, strUpdated;
	rgxLink= new RegExp('\\[.*\\](' + strUUID + ')');
	debugger;
	strUpdated = strText.replace(rgxLink, '[' + options.linkname + '](' +strUUID + ')');
	tree.beginUpdates();
		node.setText(strUpdated);
	tree.endUpdates();
	tree.ensureClassified();
}

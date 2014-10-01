define(function (require) {
	'use strict';

	describe('toggle hide done items', function () {
		var MarkdownTaxonomy = require('ft/taxonomy/markdowntaxonomy').MarkdownTaxonomy,
			Taxonomies = require('ft/core/taxonomies'),
			Editor = require('ft/editor/editor').Editor,
			taxonomy = Taxonomies.taxonomy({
				foldingtext: true,
				multimarkdown: true,
				gitmarkdown: true,
				criticMarkup: true
			}, 'markdown'),
			editor;

		beforeEach(function () {
			editor = new Editor('', taxonomy);
		});

		afterEach(function () {
			editor.removeAndCleanupForCollection();
		});

		it('should toggle path between //not @done and ///*', function () {
			editor.setNodePath('///*');
			editor.performCommand('toggle hide done items');
			expect(editor.nodePath().nodePathString).toEqual('//not @done');
			editor.performCommand('toggle hide done items');
			expect(editor.nodePath().nodePathString).toEqual('///*');
		});
	});
});

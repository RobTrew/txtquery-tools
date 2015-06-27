### Copy FoldingText for Atom selection as ft3doc:// link back to document and selected line

A [Keyboard Maestro](http://www.keyboardmaestro.com/main/) macro:

- [Copy ft3doc URL for selected line in FoldingText 3.kmmacros](./Copy%20ft3doc%20URL%20for%20selected%20line%20in%20FoldingText%203.kmmacros)
- [Copy ft3doc URL for selected line in FoldingText 3.kmmacros.zip](./Copy%20ft3doc%20URL%20for%20selected%20line%20in%20FoldingText%203.kmmacros.zip)

which copies a path back to the open [FoldingText 3 for Atom beta](http://jessegrosjean.gitbooks.io/foldingtext-for-atom-user-s-guide/content/) document, and to the currently selected line. (FT3 lines have unique and persistent ids which can be used as url link targets)

The built-in [Atom](https://atom.io/) menu command: **Atom > Edit  > Copy Path** copies a `file://` url which can be used as an argument to the **atom** command in the shell, but is not predictably handled by browsers or other applications, which may display a preview of the file, or open a Finder window to reveal it, but will not open a file and select the relevant line.

This macro also uses  **Atom > Edit  > Copy Path**, but replaces the `file://` prefix with the custom `ft3doc://` which requires simple installation (see below) of a handler app (OpenFT3DocAtLine.app), which needs to be on your system, but only needs to be run once, to register `ft3doc://` as a known handler.


### Applications
- As an external bookmark to a particular point in a document (for example from another app)
- For use in cross-file perspectives (defined in XQuery) as a link back to the lines displayed by a query.

### Use
- Install the KeyBoard Maestro macro
- Select a line or phrase in FoldingText 3 for Atom
- Run the macro with Ctrl Shift C
- Paste the resulting `ft3doc://` url wherever you need it.
- (Not that cross file and internal links withing FT3 can already be created by simple drag and Ctrl-drop)

#### `ft3doc://` 
#### A url-scheme for opening a FoldingText 3 for Atom document at a specific line
The `ft3doc://` url-scheme is registered and handled by an Applescript, [OpenFT3DocAtLine.app](./OpenFT3DocAtLine.app) [OpenFT3DocAtLine.app.zip](./OpenFT3DocAtLine.app.zip):

###### OpenFT3DocAtLine.app
- Is a [simple applescript](Source%20and%20info.plist%20for%20OpenFT3DocAtLine/OpenFT3DocAtLine.applescript) saved as an [app bundle](./OpenFT3DocAtLine.app), and
- contains an [Info.plist](Source%20and%20info.plist%20for%20OpenFT3DocAtLine/Info.plist) which registers `ft3doc://`
- contains an open url handler which:
	- Opens a specified text document in [FoldingText 3 for Atom beta](http://jessegrosjean.gitbooks.io/foldingtext-for-atom-user-s-guide/content/)
	- selects the line specified by its unique id
	- and can contain further [query, hoisting and expansion switches](http://jessegrosjean.gitbooks.io/foldingtext-for-atom-user-s-guide/content/appendix_c_path_query_parameters.html)

NB if you want to create `ftdoc3://` urls ‘by hand’ or with a script of your own, you will need to uri-encode the file path and any nodepath. There are various ways of doing this at the command line, or in an applescript, with something like:

```
on encode(strPath)
	do shell script "python -c 'import sys, urllib as ul; print ul.quote(sys.argv[1])' " & quoted form of strPath
end encode
```

Easier, of course, in Javascript:  `encodeURI()` for a whole link, or `encodeURIComponent()` for parts excluding the opening scheme name.


#### Installation

For the `ft3doc://` url scheme to be registered, [OpenFT3DocAtLine.app](./OpenFTDoc3AtLine.app) [OpenFT3DocAtLine.app.zip](./OpenFT3DocAtLine.app.zip) needs to be on your system, and needs to have been run at least once.
To do this:
- EITHER extract the copy from the [txtquery-tools](https://github.com/RobTrew/txtquery-tools) repository [zip file](https://github.com/RobTrew/txtquery-tools/archive/master.zip), and ctrl-click to allow the OS X Gate Keeper security system to run it
- OR:
	- open the .applescript text version Applescript editor,
	- save as an .app bundle
	- Ctrl-click on the .app bundle to _Open Package Contents_
	- and replace the info.plist file with the version which declares the url-scheme

[Repository .zip file](https://github.com/RobTrew/txtquery-tools/archive/master.zip)
	
##### Reference
For an explanation of this approach to registering and handling a url with an applescript.app, and the info.plist in its bundle,
See [http://www.macosxautomation.com/applescript/linktrigger/](http://www.macosxautomation.com/applescript/linktrigger/)


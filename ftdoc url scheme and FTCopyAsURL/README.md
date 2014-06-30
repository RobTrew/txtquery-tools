### Copy FoldingText selection as ftdoc:// link back to document, line, selection and filter state

The [FTCopyAsURL](./FTCopyAsURL.applescript) applescript copies the currently selected text position in [FoldingText](www.foldingtext.com), and creates a url which:
- Links back to the current document,
- restores the current selection, and: 
- also restores any filters that are currently applied to the document.

For example, the following link:

`ftdoc:///Users/houthakker/Library/Application%20Support/Notational%20Velocity/notes-2014-06-29.txt?nodepath=//@priority%20=%201?line=23?startoffset=36?endoffset=62`

1. Reopens a particular document in a Notational Velocity text file folder
2. selects text positions 36 to 62 within line 23,
3. and restores the **@//priority=1** filter  (=lines tagged priority one at **any** (//) outline level)

Note that the file path and any node path are automatically uri-encoded by the script.

### Applications
- As a kind of bookmark to a particular point in a document
- As a way, when using the [FoldingText CLI](https://www.npmjs.org/package/foldingtext) to generate a single perspective or report from several documents, of creating links which jump back from the perspective to a specific document and line.

### Use
- Select a line or phrase in FoldingText
- Run [FTCopyAsURL](./FTCopyAsURL.applescript)
- Paste the resulting ftdoc:// url wherever you need it.
- (It can be used for example, to provide active links between or within FoldingText documents)

#### ftdoc:// url-scheme for opening a FoldingText document at a specific line
The ftdoc:// url-scheme is registered and handled by an Applescript, [OpenFTDocAtLine](./OpenFTDocAtLine.app) the following:

###### OpenFTDocAtLine.app
- Is an [applescript](Source%20and%20info.plist%20for%20OpenFTDocAtLine/OpenFTDocAtLine.applescript) saved as an .app bundle
- contains an [Info.plist](Source%20and%20info.plist%20for%20OpenFTDocAtLine/Info.plist) which registers `ftdoc://`
- contains an open url handler which:
	- Opens a specified text document in [FoldingText](www.foldingtext.com)
	- applies any filter given in a `?nodepath=`
	- selects any line specified in a `?line=` switch
			(if the line is hidden by the nodepath filter, the editor unfolds just enough to make the line visible)
	- optionally restricts the selection to a part of the line, using any character position specified by either or both of the following switches
		- `?startoffset=`
		- `?endoffset=`

NB if you want to create _ftdoc://_ urls ‘by hand’ or with a script of your own, you will need to uri-encode the file path and any nodepath. There are various ways of doing this at the command line, or in an applescript, with something like:

```
on encode(strPath)
	do shell script "python -c 'import sys, urllib as ul; print ul.quote(sys.argv[1])' " & quoted form of strPath
end encode
```

Easier, of course, in Javascript:  `encodeURI()` for a whole link, or `encodeURIComponent()` for parts excluding the opening scheme name.


#### Installation

For the _ftdoc://_ url scheme to be registered, [OpenFTDocAtLine](./OpenFTDocAtLine.app) needs to be on your system, and needs to have been run at least once.
To do this:
- EITHER extract the copy from the [txtquery-tools](https://github.com/RobTrew/txtquery-tools) repository [zip file](https://github.com/RobTrew/txtquery-tools/archive/master.zip), and ctrl-click to allow the OS X Gate Keep security system to run it
- OR:
	- open the .applescript text version Applescript editor,
	- save as an .app bundle
	- Ctrl-click on the .app bundle to _Open Package Contents_
	- and replace the info.plist file with the version which declares the url-scheme

[Repository .zip file](https://github.com/RobTrew/txtquery-tools/archive/master.zip)
	
##### Reference
For an explanation of this approach to registering and handling a url with an applescript.app, and the info.plist in its bundle,
See [http://www.macosxautomation.com/applescript/linktrigger/]()

(Many thanks to Jamie Kowalski for drawing my attention to this approach, which he uses in his excellent [wikilink plugin](https://github.com/jamiekowalski/foldingtext-extra/blob/master/wikilink.ftplugin/README.md) for FoldingText)



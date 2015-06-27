property pTitle : "Register and handle ft3doc:// url scheme"
property pVer : "0.01"
property pAuthor : "Rob Trew  @complexpoint"
property pDescription : "

	Use in conjunction with Atom > Edit > Copy Path  (Ctrl Shift C) to copy
	a URL which opens the specified FoldingText 3 document, selecting the line at which the path was copied.
	https://github.com/FoldingText/foldingtext-for-atom

"
on open location strFT3URL
	do shell script "/usr/local/bin/atom file" & (text 7 thru -1 of strFT3URL)
end open location

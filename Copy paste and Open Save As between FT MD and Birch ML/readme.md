#### FoldingText MD ⇄ Birch light HTML outlines

A couple of Yosemite Javascript for Applications [scripts](https://github.com/RobTrew/txtquery-tools/tree/master/Copy%20paste%20and%20Open%20Save%20As%20between%20FT%20MD%20and%20Birch%20ML) which can be run from Script Editor or assigned to keystrokes with something like Keyboard Maestro.

1. [FoldingText / MD --> Birch outline](https://github.com/RobTrew/txtquery-tools/blob/master/Copy%20paste%20and%20Open%20Save%20As%20between%20FT%20MD%20and%20Birch%20ML/FTSaveAsBML.applescript)
3. [Birch outline --> FoldingText MD format](https://github.com/RobTrew/txtquery-tools/blob/master/Copy%20paste%20and%20Open%20Save%20As%20between%20FT%20MD%20and%20Birch%20ML/BML2MD.applescript)

[Both](https://github.com/RobTrew/txtquery-tools/tree/master/Copy%20paste%20and%20Open%20Save%20As%20between%20FT%20MD%20and%20Birch%20ML) can be used either for clipboard copy paste or for file system Open and Save As

(Probably makes sense to save two versions of each, adjusting the options switches at the top of each script to 0 or 1 values to select between clipboard and file operations)

Note: Ver 12 and above of the FoldingText Save As Birch script use CommonMark (rather than FoldingText) line type names.
This is for compatibility with Jesse's Grosjean's `birch-markdown` package.

**Installation** - paste the code into Yosemite Script Editor, setting the editor language option to Javascript (pull-down option at top left), and save as a compiled .scpt file

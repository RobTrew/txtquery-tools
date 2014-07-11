#### NAME
**txtquery** -- grouped and sorted queries of sets of `@key(value)` tagged [FoldingText/TaskPaper](http://www.foldingtext.com) files

#### TWO VERSIONS
1. FoldingText .ftplugin + an Applescript which uses it.
2. A shell script

The **plugin** and its **Applescript** are useful for experimentation with TXTQUERY custom reports, but only generate perspectives for the current document that is open in FoldingText.

The **Shell script** uses the https://www.npmjs.org/package/foldingtext and the TXTQuery.js file, and generates grouped and sorted reports by querying sets of several files.

#### SHELL SCRIPT SYNOPSIS
	txtquery.sh [-m] [-r report name|index] [-q query name|index] [options]
#### SHELL SCRIPT SYNOPSISDESCRIPTION
**txtquery** generates Markdown-formatted custom reports by applying FLWOR-style queries to sets of `@key(value)` tagged text files.

The FLWOR queries which it uses are stored in .json menu files. These use [FoldingText](http://www.foldingtext.com) nodepath syntax (FoldingText > Help > NodePaths Guide) to filter text nodes by their tags, values, and text content, and can also include clauses like:

- Let
- Grouped By (as in Xquery 3)
- Order by
- Return (optionally nested)


(Note that the tag and text filtering is all done by FoldingText nodepaths, rather than by WHERE clauses)

Each query FLWOR may also contain a description of the set(s) of text files to which it will be applied.
If a query lacks a 'Sources' clause, then it can fall back to:

1.	Any defaults sources clause in the menu file, or (in the absence of a menu-level sources clause)
2.	and thence to any defaults sources defined at the head of this script.

All of these defaults for source text files can, however, be overriden by command line source switches (see below)
including `-mtime` (last modified) and other Bash `find` command filter switches.

For installation, and more detail on sources etc, see below.

#### SHELL SCRIPT SYNOPSISOPTIONS

	-h help - display this help string
	-c collections (paths or globs) - sets of text files to query
	-d documents (paths or globs) - documents to query
	-f file (path to an alternative ViewMenu.json)
	-i include a <!-- non-printing report-description header --> in the report
	-k Marked - view the report in [Marked](http://markedapp2.com)
	-l last modified (N[smhdw]) - only query files last modified within period
	-m menu - display the menu of report types in ViewMenu.json (or of -f above)
	-o output (path) - target file path for report (default is STDOUT)
	-r report (name|index) - generate a report of the type named or indicated
	-s switches (string) - additional source text switches for Bash Find
	-t types of file (comma delimited extension list like 'txt,md,ft')
	-v print version numbers of script(s) and FoldingText CLI
	-q query (name|index) output the FLWOR definition of the indicated type

#### INSTALLATION AND DEPENDENCIES

##### FoldingText plugin and Applescript

Requires: [.ftplugin folder](https://github.com/RobTrew/txtquery-tools) and its contents, [ftdoc:// url scheme]((https://github.com/RobTrew/txtquery-tools) )

1. Copy the Perspectives.ftplugin folder and its contents to the FT ‘Application Folder’ (FoldingText > File > Application Folder)
2. Close and restart FoldingText
3. Check in FoldingText > Plugin manager that the Perspectives plugin installed without errors
4. Open a @key(value) tagged document in FoldingText
4. Run the Perspectives Applescript, and choose one of the Group by Tags perspectives from the menu

Requires: [TXTQuery.js](https://github.com/RobTrew/txtquery-tools), [ftdoc:// url scheme](https://github.com/RobTrew/txtquery-tools), [FoldingText CLI plugin](https://www.npmjs.org/package/foldingtext)

1. Copy TXTQuery.js to the same folder as this script
2. Follow instructions at https://www.npmjs.org/package/foldingtext to install the FT CLI
3. At the top of this script edit the value of PathToFT to match the path of the FT executable on your system.
4. In terminal.app, cd to the folder containing this script, and make it executable (chmod +x ./txtquery.sh)

#### HOW IT WORKS

The set of specified files is concatenated together into a temporary snowball, which is read by the
[FoldingText CLI tool](https://www.npmjs.org/package/foldingtext) into a FoldingText parse tree.

This allows for FoldingText nodepath filtering, to which a FoldingText .js script adds nested grouping and sorting by tags and their values. Tracking the size and position of each component file in the snowball also makes it possible for lines in the generated reports to contain hyperlinks (ftdoc:// tp3doc://) back to particular source documents and the corresponding lines within them.

FLWOR 'Return' clauses allow complete flexibility in the formatting (Markdown or other), of headings subheadings and data linesin the generated reports. A command line switch provides the option of viewing the output reports in Brett Terpstra's [Marked](http://markedapp2.com) as soon as they are generated.

#### AVOID QUERYING THE REPORT FILES :-)

Reports, like their sources, are plain text files, and may conceivably contain tags. To avoid circularity and ballooning duplication, it's sensible to make sure that your report output paths are not included in your report source paths :-)

#### DEFINING SOURCES
##### Collections
Any paths listed (comma-delimited) under the *collections* key of a query source (or specified on the command line with a `-c` switch) are interpreted as references to SETS of documents.

1. A globbed path (ending in *, for example) will be expanded to a list of files
2. A folder path will be expanded to a list of the folder contents (bash find -maxdepth N can be added with the -s switch).
3. If the path is to a single text file, that file will be assumed to contain a simple list of paths, each of which will be queried.
 
##### Documents
Any paths listed (comma-delimited) under the *documents* key of a query source (or specified on the command line with a `-d` switch) are interpreted as *direct* references to text files to be queried.
Globs and folders will still be expanded, any path is to single text file, it will be treated as a source to be queried, rather than being read as a list of paths to query.


#### Syntax of the FLWOR queries

- Essentially an initial sketch of a small subset of XQUERY 3 FLOWR, in JSON format, but not yet documented.
- It may be quicker to describe a query or report template to me (Rob Trew @complexpoint on Twitter), and get me to quickly sketch it, than to struggle inductively with the (still rough) syntax yourself :-)

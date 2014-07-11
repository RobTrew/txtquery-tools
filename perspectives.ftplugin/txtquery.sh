#!/bin/bash -e
# TXTQUERY -- Custom multi-file perspectives (grouped and sorted reports) for @key(value) tagged plain text
# A shell script which gathers and sends source files to a FLWOR-based .js script for
# Hog Bay Software's [FoldingText CLI](https://www.npmjs.org/package/foldingtext)
# Written by Rob Trew 2014
# https://github.com/RobTrew/txtquery-tools
Title="txtQuery"
Ver="0.24"
DEPENDENCIES="TXTQuery.js, https://www.npmjs.org/package/foldingtext"

# EDIT THIS LINE TO MATCH THE PATH OF The FoldingText CLI executable FT ON YOUR INSTALLATION
PathToFT=/usr/local/lib/node_modules/foldingtext/bin/ft
# ( install from https://www.npmjs.org/package/foldingtext )

HelpString="NAME
	txtquery -- Grouped and sorted multi-file queries of @key(value) tagged FoldingText/TaskPaper plain text
SYNOPSIS
	%s: [-m] [-r report name|index] [-q query name|index] [options]
DESCRIPTION
	txtquery generates Markdown-formatted custom reports by applying FLWOR-style queries to sets of @key(value) tagged text files.
	The FLWOR queries which it uses are stored in ViewMenu.json menu files. These use FoldingText nodepath syntax
	to filter text nodes by their tags, values, and text content, and can also include clauses like:
		- Let
		- Grouped By (as in Xquery 3)
		- Order by
		- Return (optionally nested)

	(Note that the tag and text filtering is all done by FoldingText nodepaths, rather than by WHERE clauses)

	Each query FLWOR may also contain a description of the set(s) of text files to which it will be applied.
	If a query lacks a 'Sources' clause, then it can fall back to:
		1.	Any defaults sources clause in the menu file, or (in the absence of a menu-level sources clause)
		2. and thence to any defaults sources defined at the head of this script.

	All of these defaults for source text files can, however, be overriden by command line source switches (see below)
	including -mtime (last modified) and other Bash find command filter switches. For installation, and more detail on sources etc see below.

OPTIONS
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

INSTALLATION AND DEPENDENCIES
	Requires: $DEPENDENCIES
	1. Copy TXTQuery.js to the same folder as this script
	2. Follow instructions at https://www.npmjs.org/package/foldingtext to install the FT CLI
	3. At the top of this script edit the value of PathToFT to match the path of the FT executable on your system.
	4. In terminal.app, cd to the folder containing this script, and make it executable (chmod +x ./txtquery.sh)

HOW IT WORKS

	The set of specified files is concatenated together into a temporary snowball, which is read by the
	[FoldingText CLI tool](https://www.npmjs.org/package/foldingtext) into a FoldingText parse tree.
	This allows for FoldingText nodepath filtering, to which a FoldingText .js script adds nested grouping and sorting by tags and
	their values. Tracking the size and position of each component file in the snowball also makes it possible for lines in the
	generated reports to contain hyperlinks (ftdoc:// tp3doc://) back to particular source documents and the corresponding lines within them.
	FLWOR 'Return' clauses allow complete flexibility in the formatting (Markdown or other), of headings subheadings and data lines
	in the generated reports. A command line switch provides the option of viewing the output reports in Brett Terpstra's
	[Marked](http://markedapp2.com) as soon as they are generated.
	(The temporary snowball is deleted when the report has been generated).

AVOID QUERYING THE REPORT FILES :-)

	Reports, like their sources, are plain text files, and may conceivably contain tags. To avoid circularity and ballooning duplication,
	it's sensible to make sure that your report output paths are not included in your report source paths :-)

DEFINING SOURCES
	Collections:
		Any paths listed (comma-delimited) under the *collections* key of a query source
		(or specified on the command line with a -c switch) are interpreted as references to SETS of documents.
			1. A globbed path (ending in *, for example) will be expanded to a list of files
			2. A folder path will be expanded to a list of the folder contents (bash find -maxdepth N can be added with the -s switch).
			3. If the path is to a single text file, that file will be assumed to contain a simple list of paths, each of which will be queried.
	Documents:
		Any paths listed (comma-delimited) under the *documents* key of a query source
		(or specified on the command line with a -d switch) are interpreted as *direct* references to text files to be queried.
		Globs and folders will still be expanded, any path is to single text file, it will be treated as a source to be queried,
		rather than being read as a list of paths to query.
"

# THIS IS THE DEFAULT PATH TO THE OS X JAVASCRIPT CORE
JSC=/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc

# EDIT THE PATHS TO THE DEFAULT FILES TO SCAN FOR YOUR REPORTS
# (E.G.LISTS OF ACTIVE PROJECTS, FILES LIKELY TO CONTAIN REPORTABLE DATES ETC)

## Default Collection and Document paths below can include any of the following: [$HOME ~ * ?]
## Quoting of DEFAULTCOLLECTION | DEFAULTDOC values can be single or double
## Quoting in fn:collection() or fn:doc() arguments isn't needed (and won't work)
## Escaping of spaces in file paths is not necessary (optional) in fn: arguments or in DEFAULTS
## Examples:
##		  DEFAULTCOLLECTION='$HOME/Library/Application Support/Notational Velocity/project*'
##		  DEFAULTDOC="~/Library/Application Support/Notational Velocity/inbox.txt"

# FNDOC: default paths documents to directly query
# (see DEFAULTDOC below)
FNDOC=1
# FNCOLLECTION: default folders or globs of files,
#				   or paths of documents containing *lists* of paths to query
FNCOLLECTION=2

# WHAT DO WE USE WHEN NO SOURCES ARE SPECIFIED BY THE COMMAND LINE OR THE FLOWR ?
# Default docs=1, default collections=2, both=3 (FNDOC + FNCOLLECTION)
# (see DEFAULTCOLLECTION below)
#DEFAULTSOURCE=$FNCOLLECTION+$FNDOC
DEFAULTSOURCE=$FNCOLLECTION

#Default menu file ?
#(A default filed creeated if nothing specified, or found in the script folder)
MENUFILE="ViewMenu.json"

# ALL SOURCE DEFAULTS CAN BE OVERRIDDEN IN THE FOLLOWING ORDER OF PRECEDENCE:
# 1. CLI SWITCHES CAN OVERRIDE ALL ELSE [ -c -d -l -t]
# 2. the 'source' object of a FLOWR overrides any defaults in its menu file
# 3. any 'sources' object in a menu file override the script defaults, and
# 4. the following script defaults are used as the last resort:

# INPUTS
DEFAULTCOLLECTION="~/Library/Application Support/Notational Velocity/project*"
DEFAULTDOC="~/Library/Application Support/Notational Velocity/inbox.txt"
DEFAULT_LASTMOD="90d" # only query files modified in last 30 days N[smhdw]
DEFAULT_IN_TYPES="txt,md,ft" #use comma-delimited list, no spaces
DEFAULT_SWITCHES="-maxdepth 1" # any additional bash find switches like

# OUTPUTS (should be outside the scope of INPUTS above)
VIEWFOLDER="~/ViewFolder"

ACTIVECOLLN=
ACTIVEDOC=
ACTIVE_LASTMOD=
ACTIVE_TYPES=
ACTIVE_SWITCHES=
USE_SRC_COLLN=
USE_SRC_DOC=

MOD_SWITCH=
CLI_SWITCHES="$0 $@"

DEFAULT_OUT_TYPE="txt"
REPORTPATH=

shopt -s nocaseglob # for case-insensitive file matching
FLWOR=' // example
	{"Grouped by tag": {
		"sources":{
			"collections": "~/Library/Application Support/Notational Velocity/project*",
			"docs": "~/Library/Application Support/Notational Velocity/inbox.txt",
			"filetypes": "txt,md,ft",
			"mtime": "42d" // only files modified in the last 42 days - see teminal.app man find
		},
		"for": "$tag in fn:tagSet()",
		"let": "$items = //@{$tag}",
		"orderby": "$tag",
		"return": [
			"#### fn:sentence_case({$tag}) (fn:count($items))",
			{
				"for": "$item in //@{$tag}",
				"return": "- {$item} ({$item@$tag})"
			},
			""
		]
	}}'

# SHELL FUNCTIONS FOR REPORT SOURCE PARSING ("source:" KEY AND DEFAULTS)

function sourceFileArray () {
	# If the FLWOR has a source with a 'collections' key,
	# OR A CLI SWITCH SPECIFIES A COLLECTION then use the
	# collections values which we have just updated from the FLWOR and
	# the menu file
	# Also, if the FLWOR has a source with a 'docs' key,
	# OR A CLI SWITCH SPECIFIES A DOC then use the
	# docs values which we have just updated too (additive: either or both)
	# Note (give expanSections a boolean flag when expanding collections)
	if ($USE_SRC_COLLN || $USE_SRC_DOC); then
		if $USE_SRC_COLLN ; then expandSections "$ACTIVECOLLN" true; fi
		if $USE_SRC_DOC; then expandSections "$ACTIVEDOC"; fi
	else
		# but if FLWOR has NEITHER 'collections' NOR 'docs' keys, then
		# fall back to the default policy (see DEFAULTSOURCE=1/2/3)
		# near the start of this script
		if (($DEFAULTSOURCE & $FNCOLLECTION)); then
			expandSections "$ACTIVECOLLN" true
		fi
		if (($DEFAULTSOURCE & $FNDOC)); then
			expandSections "$ACTIVEDOC"
		fi
	fi
}

function expandSections () {
	# in $2 we pass on a possibly empty flag for collections (not docs)
	if [[ $1 == *,* ]]; then
		IFS=',' read -a TermArray <<< $1
		unset i
		for i in ${TermArray[@]}
			do expandSource $i $2
		done
	else
		expandSource "$1" $2
	fi
}

function setModSwitch () {
	# -l switch or source.mtime to restrict match files
	# to those modified in last N days (default) or [smhdw]
	if [ -z $1 -o $1 == "-" ]; then
		MOD_SWITCH=
	else
		if [[ "$1" =~ ^[0-9]+[smhdw]* ]]; then
			if [[ "$1" =~ ^[0-9]+[smhdw] ]]; then
				MOD_SWITCH="-mtime -$1"
			else
				MOD_SWITCH="-mtime -$1d"
			fi
		else
			echo "last modified (-l or mtime) should match [1-9]+[smhdw]*"
			exit 1
		fi
	fi
}

function expandSource () {
	local ISCOLLN=
	# First translate/expand the term (folder, glob, file containg paths) to an array of file paths
	SourceLine="$1" # record for any subsequent error messages
	ISCOLLN="$2" # flag to indicate that we are expanding a collection
	set -f #suspend file globbing, lest we get multiple files too soon
	local ARG1="$(echo "$1" | sed s_~_"$HOME"_)"

	#local ARG1=$(eval echo $1) #In case an embedded string contains `$HOME` or `~`
	local extnGroup="\.(${ACTIVE_TYPES//,/|})" #eg txt,md,ft --> (txt|md|ft)
	set +f #restore globbing
	# Normalise to *no* escaping of spaces in file paths
	ARG1=$(echo "$ARG1" | sed -e 's/\\ / /g')

	local -a FileArray
	local NAME_PART=$(basename "$ARG1")

	if [[ $NAME_PART =~ .*[\*\?]+.* ]]; then
		#limit the glob with 'find -name'
		local FOLDER_PART=$(dirname "$ARG1")
		if [[ "$NAME_PART" =~ ^.*$extnGroup$ ]]; then #has extension, match name directly
			IFS=$'\n' FileArray=($(eval "find \"$FOLDER_PART\" $ACTIVE_SWITCHES -name \"$NAME_PART\" $MOD_SWITCH" ))
		else
			# Translate Glob '*' to Regex '.*', so that we can append a pattern like (txt|md|ft)
			IFS=$'\n' FileArray=($(eval "find -E \"$FOLDER_PART\" $ACTIVE_SWITCHES -iregex \".*/${NAME_PART//\*/.*}$extnGroup\" $MOD_SWITCH"))
		fi
	else
		if [[ -d "$ARG1" ]]; then # a directory - match all txt ft md etc (see/edit DEFAULT_IN_TYPES at top)
			IFS=$'\n' FileArray=($(eval "find -E \"$ARG1\" $ACTIVE_SWITCHES -iregex \".*$extnGroup\" $MOD_SWITCH"))
		else # if a single file,
			if [[ -f "$ARG1" ]]; then
				if [[ -z "$ISCOLLN" ]]; then # EITHER (for fn:doc) assume that it is itself a source (tagged text file)
					IFS=$'\n' FileArray=("$ARG1")
				else
					# OR (for fn:collection) assume that it contains a list of paths, rather than tagged text
					IFS=$'\n' FileArray=($(cat "$ARG1"))
				fi
			else
				# File not found, but we'll report that later to terminal and log
				IFS=$'\n' FileArray=("$ARG1")
			fi
		fi
	fi
	# Then append the array of paths to the source array

	SourceArray=("${SourceArray[@]}" "${FileArray[@]}")
}


function addFileOrFlagError () {
	#$1 is a candidate file
	#$2 is the concatenating snowball
	local MSG=
	# File tuples: (path, startPosn, charCount, lineCount)
	local CHARCOUNT=0
	local LINECOUNT=0
	local STATS
	local QUOTED
	local isMissing=
	#local isNotText=
	local fType=
	local fName

	#exec 3> /dev/tty
	if [[ -f "$1" ]]; then
		#fType=$(file -b "$1")
		#if  [[ $fType == *text* ]]; then # this test fails with Non-Roman/Roman character set mixtures in my locale
			# so we'll fall back to relying on the file extension filtering
			# Add the text file to the snowball, recording its starting character offset and start line
			if [[ $1 == *"\""* ]]; then fName="${1//\"/\\\"}"
			else fName="$1"; fi  # escape any double quotes for json

			# CONCATENATE ADDITIONAL FILE INTO WORKING SNOWBALL
			cat $1 >> $2
			# ADD A 10 Byte FILE SEGMENTATION BREAK (for FT parsing)
			printf "\n\n\n# ---\n\n" >> $2

			IFS=' ' read -ra STATS <<< $(wc -lm "$1") # get line and character size from wc
			FileTriplets=("${FileTriplets[@]}" "\"$fName\"" $STARTPOSN $STARTLINE) # record starting position
			LINECOUNT=${STATS[0]} # and increment position to file end for any following file
			CHARCOUNT=${STATS[1]}
			STARTPOSN=$(($STARTPOSN + $CHARCOUNT + 10)) #(see the segmentation
			STARTLINE=$(($STARTLINE + $LINECOUNT + 5)) #  break above ...)
		#else
		#	isNotText=1
		#	MSG="FILE TYPE APPEARS TO BE: \"$fType\" (as reported by BASH 'file -b' command)"
		#fi
	else
		isMissing=1
		MSG="FILE NOT FOUND"
	fi

	if [[ "$isMissing" ]]; then
		SOURCE=$(echo $SourceLine | sed 's/^ *//')
		echo -e "$(date +%FT%T%Z)\n$MSG evaluating $SOURCE\nSPECIFIC FILE: $i\n" | tee TempLog.txt
		touch FullLog.txt
		cat TempLog.txt >> FullLog.txt
	fi
}

function checkDir () {
	local fpath=
	if [[ -n $1 ]]; then
		if [[ ! -d "$1" ]]; then
			fpath="${1%/*}"
			if [[ -d "$fpath" ]]; then
				mkdir "$1"
			else
				echo "output folder not found: $1"
				exit 1
			fi
		fi
	fi
}

function readSourceSwitches () {
	# First clear previous COLLN/DOC settings if either -c or -d switches used
	if [[ "$cflag" || "$dflag" ]]; then
		USE_SRC_COLLN=false
		USE_SRC_DOC=false
	fi
	# then use only switch-specified sources
	if [ "$cflag" ]; then
		USE_SRC_COLLN=true; ACTIVECOLLN="$cval"
	fi
	if [ "$dflag" ]; then
		USE_SRC_DOC=true; ACTIVEDOC="$dval"
	fi
	if [ "$lflag" ]; then setLastMod "$lval"; fi #bash find -mtime
	if [ "$tflag" ]; then ACTIVE_TYPES="$tval"; fi
}

function pathToFile() {
  local FULLPATH=

  cd $(dirname $1)
  FULLPATH="$PWD/$(basename $1)"
  echo ${FULLPATH/$HOME/'~'}
}

function writeReport () {
	## PARSE SOURCES SPEC AND BUILD THE SNOWBALL FILE, PREPARING A PACKING LIST
	declare -a TermArray
	declare -a SourceArray
	declare -a FileTriplets # path, startPosn, startLine
	local SRC_SETTINGS=
	local strCollns=""
	local strDocs""
	local MenuPath=$(pathToFile "$MENUFILE")
	STARTPOSN=0 # used in snowball file metrics - see addFileOrFlagError () above
	STARTLINE=0 # ditto

#	echo "MENUPATH $MenuPath"
#	exit 0

	# Default sources have been assumed
	# and FLOWR or menu settings have been allowed to override them
	# Now let any CLI source switches -c -d -l -t override what we have

	# Read any command line source switches (they override all other settings)
	readSourceSwitches

	# Finalise any switch string for 'last modified' filtering
	setModSwitch $ACTIVE_LASTMOD

	# Build source array
	sourceFileArray "$FLWOR"

	# clear the TempLog.txt file
	touch TempLog.txt
	rm TempLog.txt

	## ADD FOUND FILES TO THE SNOWBALL,
	## AND LOG ANY "FILE NOT FOUND" TO STDOUT AND LOCAL FILE

	### MAKE A PLACE FOR THE SNOWBALL
	# Create a random temp directory
	until [ -n "$tmp_dir" -a ! -d "$tmp_dir" ]; do
		 tmp_dir="/tmp/combined.${RANDOM}${RANDOM}${RANDOM}"
	done

	mkdir -p -m 0700 $tmp_dir

	## and a random temp file therein
	tmp_file="$tmp_dir/combined.${RANDOM}${RANDOM}${RANDOM}"
	touch $tmp_file && chmod 0600 $tmp_file

	### AND PACK THE SNOWBALL, MAKING A PACKING LIST AS WE GO

	for i in ${SourceArray[@]}
		do addFileOrFlagError $i $tmp_file
	done

	# Assemble file paths and their start positions (character and line)
	# as a list for JSON
	PACKLIST="["$(IFS=,; echo "${FileTriplets[*]}")"]"

	# Gather the active source settings in a JSON format,
	# so that they can be shown
	# in a non-printing header to the report
	if ( $USE_SRC_COLLN ); then
		strColln="\"collections\":\"$ACTIVECOLLN\", "
	fi
	if ( $USE_SRC_DOC ); then
		strDoc="\"docs\":\"$ACTIVEDOC\", "
	fi

	SRC_SETTINGS="{\"cmdline\":\"$CLI_SWITCHES\", $strColln$strDoc\"filetypes\":\"$ACTIVE_TYPES\", \"mtime\":\"$ACTIVE_LASTMOD\",
		\"switches\":\"$ACTIVE_SWITCHES\", \"menufile\":\"$MenuPath\", \"menuitem\":\"$rval\"}"

	# CALL COMMAND LINE FOLDINGTEXT
	# WITH A JS FUNCTION WHICH WRITES A REPORT
	# SENDING THE OUTPUT TO STDOUT
	# echo "SRC_SETTINGS: $SRC_SETTINGS"
	# exit 0

	OPTIONSET="{\"cmd\":\"customViewByName\", \"viewname\":\"$rval\", \"packlist\":$PACKLIST, \"sourcespec\":$SRC_SETTINGS, \"frontmatter\":$iflag, \"viewjson\":$FLWOR}"

	strReport=$($PathToFT evaluate -p "$OPTIONSET" TXTQuery.js $tmp_file)
	# Expand any ~ or $HOME etc
	VIEWFOLDER="$(echo "$VIEWFOLDER" | sed s_~_"$HOME"_)"
	checkDir "$VIEWFOLDER"

	# Default output name and folder may be overriden by -o switch
	# (Note: we need to strip out any / characters from the menu name to use it in a path
	writeOut "$strReport" "${VIEWFOLDER%/}/${rval//\//}"
	echo "$strReport"

	# optionally open in Brett Terpstra's [Marked](http://markedapp2.com)
	if [ "$kflag" ]; then
		# echo "$REPORTPATH"
		open -a "Marked" "$REPORTPATH"
	fi

	# And delete the temporary concatenation of files
	#cleanup="rm -rf $tmp_dir"
	#trap $($cleanup) ABRT EXIT HUP INT QUIT
	rm -rf $tmp_dir
}

function getMenu () {
	# If no menu file is found, get a default one from TXTQuery.js and save it to the path
	fMissing=
	if [ $# -ne 0 ]; then
		MENUFILE=$1;
	fi
	if [ ! -f "$MENUFILE" ]; then
		MNUJSON=$("$JSC" -e "print(txtFLOWR(null, '{\"cmd\":\"defaultsJSON\"}')); $(cat TXTQuery.js)")
		fMissing=1
	else
		MNUJSON=$(cat "$MENUFILE")
	fi
		IFS=$'\n' VIEWLIST=($("$JSC" -e "
			var dctMenu=$MNUJSON, dctViews = dctMenu['menu'];
			if (dctViews) {
				print(Object.keys(dctViews).sort().join('\n'));
			} else {
				print('...');
			}"))

	if [ "$fMissing" ]; then echo "$MNUJSON" > $MENUFILE; fi
}

function arrayContains () {
	# Array membership test
	# Call with 2 args: Array name (no preceding dollar), and exact string to seek
	DBL='\"'
	if [[ $(typeset -p $1) == *$DBL$2$DBL* ]]; then
		echo true
	else
		echo false
	fi
}

# Sorted list of the view names in $MNUFILE
function viewMenu () {
	getMenu $1
	local iIndex=1
	echo "MENU: Reports/perspectives defined in $MENUFILE"
	for i in ${VIEWLIST[@]}
		do printf "$iIndex\t$i\n"; iIndex=$((iIndex+1))
	done
}

function getNamedFLWOR () {
	# Return four lines (comma-delimited, where values are multiple)
	# of source settings (collections, docs, filetypes, lastmod)
	# Giving priority to any FWOR.sources and falling back to any MNU.sources
	# Then one menu name line,
	# and the rest all JSON lines.
	# reset any defined Source setting lines
	# and set the FLWOR variable
	local flworNAME=$1
	local varVal=
	local arrLines=
	# Get FLWOR and parse out:
	# updates to source setting defaults, and whether flowr
	# contains its own collections: and or documents: keys
	varLines=$("$JSC" -e "
	var dctMenu=$MNUJSON, dctViews=dctMenu['menu'], dctMsrc, dctFsrc,
		lstKeys, dctFlwor, strKey='$flworNAME', blnColln=false, blnDoc=false,
		varMcol, varMdoc, varMtype, varMswitches, varMlastmod,
		varFcol, varFdoc, varFtype, varFswitches, varFlastmod, varVal,
		strC='collections', strD='docs', strM='mtime',
		strS='switches', strT='filetypes';
	function fmt(varVal) {
		var varDelimd=varVal;
		if (varVal) {
			if ((typeof varVal.join)=='function') varDelimd=varVal.join(',');
		}
		return varDelimd;
	}
	if (dctViews) {
		dctMsrc=dctMenu['sources'];
		dctFlwor=dctViews[strKey];
		if (!dctFlwor && !isNaN(strKey)) {
			lstKeys=Object.keys(dctViews).sort();
			strKey=lstKeys[parseInt(strKey)-1];
			dctFlwor=dctViews[strKey];
		}
		if (dctFlwor) {
			dctFsrc=dctFlwor['sources'];
			if (dctFsrc) { // FLWOR settings
				lstKeys=Object.keys(dctFsrc);
				blnColln=(lstKeys.indexOf(strC)!==-1);
				blnDoc=(lstKeys.indexOf(strD)!==-1);
				varFcol=dctFsrc[strC]; varFdoc=dctFsrc[strD];
				varFlastmod=dctFsrc[strM]; varFswitches=dctFsrc[strS];
				varFtype=dctFsrc[strT];
			}
			if (dctMsrc) { // MENU defaults
				varMcol=dctMsrc[strC]; varMdoc=dctMsrc[strD];
				varMlastmod=dctMsrc[strM]; varMswitches=dctMsrc[strS];
				varMtype=dctMsrc[strT];
			}
			print([fmt(varFcol || varMcol), fmt(varFdoc || varMdoc),
				fmt(varFlastmod || varMlastmod),
				fmt(varFswitches || varMswitches), fmt(varFtype || varMtype),
				blnColln, blnDoc, strKey,
				JSON.stringify(dctFlwor, null, '\t')].join('\n'));
		}
	}")

	if [ ! -z "$varLines" ]; then
		local arr=()
		local line=
		local varVal=
		while read -r line; do
			arr+=("$line")
		done <<< "$varLines"
		# FIRST ASSUME THE DEFAULTS
		ACTIVECOLLN=$DEFAULTCOLLECTION
		ACTIVEDOC=$DEFAULTDOC
		ACTIVE_LASTMOD=$DEFAULT_LASTMOD
		ACTIVE_SWITCHES=$DEFAULT_SWITCHES
		ACTIVE_TYPES=$DEFAULT_IN_TYPES

		# THEN YIELD PRECEDENCE TO ANY FLWOR (or MENU DEFAULT) SOURCE SETTINGS
		varVal=${arr[0]}; if [ ! -z "$varVal" ]; then
			ACTIVECOLLN="$varVal"; fi
		varVal=${arr[1]}; if [ ! -z "$varVal" ]; then
			ACTIVEDOC="$varVal"; fi
		varVal=${arr[2]}; if [ ! -z "$varVal" ]; then
			ACTIVE_LASTMOD="$varVal"; fi
		varVal=${arr[3]}; if [ ! -z "$varVal" ]; then
			ACTIVE_SWITCHES="$varVal"; fi
		varVal=${arr[4]}; if [ ! -z "$varVal" ]; then
			ACTIVE_TYPES="$varVal"; fi

		# Two booleans - does FLWOR have own 'collections' and/or 'docs' keys?
		USE_SRC_COLLN=${arr[5]}
		USE_SRC_DOC=${arr[6]}
		rval=${arr[7]} # replace any numeric index with the matching name key
		FLWOR=$(echo "$varLines" | sed 1,8d) #rest of output
	fi
}

function namedReport () {
	local blnFound=
	getMenu $fval
	if $(arrayContains VIEWLIST $rval); then
		blnFound=1;
	elif [[ $rval =~ ^[1-9]+[0-9]*$ ]]; then
		if [ $rval -le ${#VIEWLIST[@]} ]; then
			blnFound=1
		fi
	fi
	if [[ -z $blnFound ]]; then
		echo "'$rval' not found in $MENUFILE"
	else
		# get the FLWOR and source settings from the menufile
		getNamedFLWOR $rval $fval
		# assemble the snowball and its packing list
		writeReport
	fi
}

function writeOut () {
	# WRITE string $1 to path $2 with filetype extension $3
	# CLI -o switch CAN OVERRIDE $2 and $3
	local fname=
	local fpath=
	local extn=
	local target=
	if [[ -z "$oval" ]]; then
		if [[ -z "$2" ]]; then
			echo "$1" # straight to STDOUT
			return
		else
			target="$2"
		fi
	else
		target="$oval"
	fi

	if [[ -n "$target" ]]; then
		#Expand any tilde etc
		target="$(echo "$target" | sed s_~_"$HOME"_)"

		if [[ -z $3 ]];then
			extn=$DEFAULT_OUT_TYPE
		else
			extn=${3//./}
		fi

		if [[ -d "$target" ]]; then
			fpath=${target%/} #strip any final slash from folder name/
			if [[ -z "$2" || -d "$2" ]]; then
				fpath="$fpath/report$(date +%FT%T%Z).$extn"
			else
				fpath="$fpath/$fname.$extn"
				echo "CLEARED PATH: $fpath"
			fi
			REPORTPATH="$fpath"
		else #destination string is not a folder
			fpath=${target%/*}
			fname=${target##*/}
			if [[ -z "$fpath" ]]; then
				fpath="."
				fname="$target"
			fi
			if [[ "$fname" != *\.* ]]; then fname="$fname.$extn"; fi
			if [[ -d "$fpath" ]]; then fname="${fpath%/}/$fname"; fi
			REPORTPATH="$fname"
		fi
		echo "$1" > "$REPORTPATH"
	fi
}

function namedQuery () {
	local blnFound=
	getMenu $fval
	if $(arrayContains VIEWLIST $qval); then
		blnFound=1;
	elif [[ $qval =~ ^[1-9]+[0-9]*$ ]]; then
		if [ $qval -le ${#VIEWLIST[@]} ]; then
			blnFound=1
		fi
	fi
	if [[ -z $blnFound ]]; then
		echo "'$qval' not found in $MENUFILE"
	else
		getNamedFLWOR "$qval" "$fval"
		echo "$rval" # menu name: set in getNamedFLOWR if fetched by index
		echo "$FLWOR"
	fi
}

#### --------------- MAIN STARTS HERE -----------------

cflag=
dflag=
fflag=
hflag=1
iflag=false
kflag=
lflag=
mflag=
oflag=
rflag=
sflag=
tflag=
vflag=
qflag=

cval=
dval=
fval=
lval=
pval=
qval=
rval=
sval=
tval=

while getopts :c:d:f:hikl:mo:vq:r:s:t: FOUND
do
	case $FOUND in
	c) cflag=1; hflag= # Collections to query
		cval="$OPTARG"
		;;
	d) dflag=1; hflag= # Documents to query
		dval="$OPTARG"
		;;
	f) fflag=1; hflag= # path of menu File to use (and create, if not found)
		fval="$OPTARG"
		;;
	i) iflag=true; hflag= # Include non-printing query Info in report header
		;;
	k) kflag=true; hflag= # display report in marKed
		;;
	l) lflag=1; hflag= # Last modified N[smhdw]
		lval="$OPTARG"
		;;
	m) mflag=1; hflag= # out Menu of available report types
		;;
	o) oflag=1; hflag= # set Output file
		oval="$OPTARG"
		;;
	q) qflag=1; hflag= # output json for named Query
		qval="$OPTARG"
		;;
	r) rflag=1; hflag= # output Report (n or menu-name)
		rval="$OPTARG"
		;;
	s) sflag=1; hflag= # use additional bash find Switch string
		sval="$OPTARG"
		;;
	t) tflag=1; hflag= # file Types e.g. 'txt,md,ft'
		tval="$OPTARG"
		;;
	v) vflag=1; hflag= # print Versions for scripts and FT CLI
		;;
	\:)	printf "argument missing from -%s option\n" $OPTARG
		printf "$HelpString" $(basename $0)
		#exit 2
		;;
	\?)	printf "unknown option: -%s\n" $OPTARG
		printf "$HelpString" $(basename $0)
		#exit 2
		;;
	esac >&2
	# echo "$FOUND $OPTARG"
done
	shift $(($OPTIND - 1))
	if [ "$hflag" ]; then printf "$HelpString" $(basename $0); fi
	if [ "$mflag" ]; then viewMenu "$fval"; fi
	if [ "$qflag" ]; then namedQuery "$qval" "$fval"; fi
	if [ "$rflag" ]; then namedReport "$rval" "$fval"; fi
	if [ "$vflag" ]; then
		echo "$Title ver $Ver"
		echo "FoldingText CLI ver."$($PathToFT -v)
	fi


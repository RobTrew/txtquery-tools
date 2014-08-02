#!/bin/bash
# Author: Rob Trew, https://github.com/RobTrew/txtquery-tools
# Ver: 0.2
# Puts one of the 8 emoji moon phase glyphs to (stdout|clipboard).
# Accepts three integer arguments in the order: YEAR CAL_MONTH DAY,
# If no arguments are given, it returns the phase of the moon matching the system time
# (Calculated by simple modulo arithmetic from the first moon of the Unix epoch in January 1970)
# Call at command line with *three* integer parameters ($1 for yyyy year, $2 for calendar month (1-12), $3 for day)
# e.g. chmod +x emomoon.sh; emomoon.sh 2014 8 10 (for Aug 10 2014)
YEAR=$1; MONTH=$2; DAY=$3
if [[ -z $YEAR ]]; then YEAR=$(date +"%Y"); fi
if [[ -z $MONTH ]]; then MONTH=$(date +"%-m"); fi
if [[ -z $DAY ]]; then DAY=$(date +"%-d"); fi
JSC="/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc"
EMOMOON=$("$JSC" -e "
function emoMoon(dteJS) {
	// The first new moon of the Unix epoch was at: 
	// 8:37 pm UTC  |  Wednesday, January 7, 1970 (source: Wolfram Alpha)
	var dteBase = new Date(Date.UTC(1970, 0, 7, 20, 37)),
	
	// and the length of a lunar month in seconds is 
	// 2.5514428×10^6 seconds (source: as measured by Mr Wolfram)
	nMonth = 2.5514428E+6,

	// there is a difference in seconds between Jan 7 1970 and the given date
	nsAll = (dteJS.getTime()-dteBase.getTime()) /1000,

	// and there are a number of seconds between this date and the preceding new moon,
	nsPhase= nsAll % nMonth,
	
	// which can be rewritten as a proportion of a lunar month (n/8), 
	nPropn=(nsPhase / nMonth) * 8;
	
	//and used as a rounded index into an ordered Emoji set
	return asUnicode(0x1f311 + (Math.round(nPropn) % 8));
}

function asUnicode(c) {
	var lngClear = c - 0x10000;
	return String.fromCharCode((lngClear >> 10) + 0xD800) +
		String.fromCharCode((lngClear & 0x3FF) + 0xDC00);
}
dteJS = new Date($YEAR, $(($MONTH-1)), $DAY);
print(emoMoon(dteJS));")
echo "$EMOMOON"
echo "$EMOMOON" | pbcopy
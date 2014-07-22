#!/bin/bash
# Gets emoji clockface (stdout|clipboard) with specified time (to nearest preceding half hour)
# Call at command line with *on or two* integer parameters ($1 for hours, $2 for minutes)
# e.g. chmod +x emotime.sh; emotime.sh 16 30
HRS=$1; MINS=$2
if [[ -z $HRS ]]; then HRS=0; fi
if [[ -z $MINS ]]; then MINS=0; fi
JSC="/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc"
EMOTIME=$("$JSC" -e "
function emoTime(dteJS) {
	var lngBase=0x1F54F, lngHour=(dteJS.getHours() % 12),
		iHourCode, iFullCode;
	if (lngHour) iHourCode=lngBase+lngHour; else iHourCode=lngBase+12;
	// any second offset of 12 takes us to the block of corresponding half hour icons
	if (dteJS.getMinutes() >= 30) iFullCode=iHourCode+12; else iFullCode=iHourCode;
	return asUnicode(iFullCode);
}

function asUnicode(c) {
	var lngClear = c - 0x10000;
	return String.fromCharCode( (lngClear >> 10) + 0xD800) +
		String.fromCharCode( (lngClear & 0x3FF) + 0xDC00);
}
dteJS = new Date(); dteJS.setHours($HRS, $MINS);
print(emoTime(dteJS));")
echo "$EMOTIME"
echo "$EMOTIME" | pbcopy
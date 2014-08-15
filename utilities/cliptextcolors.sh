#!/bin/bash
# Author: Rob Trew, 2014

# SPECIFY DEFAULT MESSAGE COLOR MODEL, VALUE RANGES, CYCLE COUNT

TRANSFORM_CLIPBOARD=1  #0 (or empty) to leave plain text version in clipboard, 1 to put RTF or 2 to put HTML in clipboard)
MSG="abracadabracadabracadabracadabra"
FONTFACE="Courier"
FONTSIZE="16"
SCHEME="BlackToRed" # Choose a key from set of scheme names in 'var options' below, or add a scheme

# TO USE:
# 1. Copy some plain text into the clipboard
# 2. Run this script
# 3. Colored HTML spans for each character will be written to STDOUT
# 4. if $TRANSFORM_CLIPBOARD (above) is non-zero, an RTF (=1) or HTML (=2) version will replace the plain text in the clipboard

# 	Example:

# 'BlackToRed' : {'model':'hsl',             -- 'hsl' or 'rgb'
# 'percent':[false, true, true],		        -- should the nth value of 3 be followed by '%' ?
#  p1:[255, 0], p2:[20, 100], p3:[20, 50],   -- range of values for the nth of 3 integers to cycle through  
#  cycles:2}									     -- how many Pi cycles ?  1=from start to end value 2=return to start value N=several cycles

CLIPTEXT=$(pbpaste -Prefer txt)
if [ ! -z "$CLIPTEXT" ]; then
	MSG="$CLIPTEXT"
fi

quote() {
    echo "$1" | sed "s/\([^[:alpha:]]\)/\\\\\1/g"
}

CLEAN=$(quote "$MSG")

JSC="/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc"
COLORSPANS=$("$JSC" -e "

var	options = {'msg':'$CLEAN', 'fontface':'$FONTFACE','fontsize':$FONTSIZE},
	dctPalette = {
		'BlackToRed' : {'model':'hsl', 'percent':[false, true, true],
						p1:[255, 0], p2:[20, 100], p3:[20, 50], cycles:2},
		'Gray' : {'model':'rgb', 'percent':[false, false, false],
						p1:[255, 40], p2:[255, 40], p3:[255, 40], cycles:2},
		'RainBow' : {'model':'hsl', 'percent':[false, true, true],
						p1:[0, 255], p2:[100, 100], p3:[50, 50], cycles:2},
		'RedPink' : {'model':'hsl', 'percent':[false, true, true],
					p1:[0, 0], p2:[100, 100], p3:[95, 50], cycles:2},
		'RedGrey' : {'model':'hsl', 'percent':[false, true, true],
						p1:[0, 255], p2:[100, 12], p3:[50, 80], cycles:2},
		'GreyRed' : {'model':'hsl', 'percent':[false, true, true],
						p1:[255, 0], p2:[12, 100], p3:[80, 50], cycles:2}
	},
	dctScheme=dctPalette['$SCHEME'];

function colorSpans(options) {
	var	strMsg = options.msg,
		lngChars = strMsg.length,
		nCycles = options.cycles * Math.PI,
		lstP1=options.p1,
		lstP2=options.p2,
		lstP3=options.p3,
		min1=lstP1[0], max1=lstP1[1],
		min2=lstP2[0], max2=lstP2[1],
		min3=lstP3[0], max3=lstP3[1],
		lstStart=[min1, min2, min3],
		lstFixed=[Math.round(min1).toString(), Math.round(min2).toString(), Math.round(min3).toString()],
		lstRange=[max1-min1, max2-min2, max3-min3], nRange,
		lstVal=[],
		strModel=options.model,
		lstPercent=options.percent,
		strVal='', lstSpan=[],lstHTML=[],
		nTheta, rPropn,
		i,j;

	for (i=0; i<lngChars; i+=1) {

		//Assemble a span for this char,
		nTheta = nCycles * (i/lngChars);
		rPropn = (1-Math.cos(nTheta))/2;
		lstVal=[];
		for (j=0; j<3; j+=1) {
			nRange=lstRange[j];
			if(nRange) {
				strVal=Math.round(lstStart[j]+(rPropn * lstRange[j])).toString();
			} else {
				strVal=lstFixed[j];
			}
			if (lstPercent[j]) strVal+= '%';
			lstVal.push(strVal);
		}
		lstSpan=['<span style=color:', strModel, '(', lstVal.join(','), ')>', strMsg.charAt(i),'</span>'];

		//and push this single character span onto the HTML list.
		lstHTML.push(lstSpan.join(''));
	}
	return   '<font face=' + options.fontface + ' size=' + options.fontsize + '>' + lstHTML.join('')  + '</font>';
}

for (var strKey in dctScheme) {
	options[strKey] = dctScheme[strKey];
}
print(colorSpans(options));
")
echo "$COLORSPANS"

if [[ ! -z $TRANSFORM_CLIPBOARD ]]; then
	if [ $TRANSFORM_CLIPBOARD -eq 1 ]; then
		echo "$COLORSPANS" | textutil -format html -convert rtf -inputencoding UTF-8 -stdin -stdout | pbcopy -Prefer rtf
	elif [ $TRANSFORM_CLIPBOARD -eq 2 ]; then
		echo "$COLORSPANS" | pbcopy
	fi
fi
	


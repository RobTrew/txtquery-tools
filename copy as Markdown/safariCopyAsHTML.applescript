// Yosemite JXA (Javascript for Automation) Copy As MD for Safari
// Requires a copy **in the same folder as this script**
// of html2text.py, originally contributed by Aaron Swartz z''l
// [html2text.py](https://github.com/aaronsw/html2text)
//
function run() {
	/*jshint multistr: true */
	
	//var dct = {
	//	title: "Copy as Markdown (for Safari)",
	//	ver: "0.2",
	//	description: "Runs HTML of Safari selection through html2text.py",
	//	author: "RobTrew copyright 2014",
	//	license: "MIT",
	//	site: "https://github.com/RobTrew/txtquery-tools"
	//};

	// Compacted string of simple .js code for copying Safari selection as HTML
	var strFnHTMLSeln = "(function (){var c=window.getSelection(),\
		d=c.rangeCount,a;if(d){a=document.createElement('div');\
		for(var b=0;b<d;b++)a.appendChild(c.getRangeAt(b).cloneContents());\
		return a.innerHTML}return '';}());";

	// COPY ANY SAFARI SELECTION AS HTML
	var appSafari = Application("Safari"),
		lstWindows = appSafari.windows();

	if (lstWindows.length < 2 ) return '';

	var app = Application.currentApplication(),
		oTab = appSafari.windows[0].currentTab,
		strHTML = appSafari.doJavaScript(strFnHTMLSeln, { in : oTab }),
		strCMD, lstPath, strPyPath;
		
	// APPLY html2text.py (must be in the same folder as this script) to convert to MD
	// Also copy to clibboard
	app.includeStandardAdditions = true;
	lstPath = app.pathTo(this).toString().split('/');
	lstPath.pop();
	lstPath.push('html2text.py');
	strPyPath = lstPath.join('/');
	
	//Set UTF-8 in the sh shell, pass the HTML to the @aaronsw Python script, and pipe to pbCopy
	strCMD='LANGSTATE="$(defaults read -g AppleLocale).UTF-8"; if [[ "$LC_CTYPE" != *"UTF-8"* ]]; then export LC_ALL="$LANGSTATE" ; fi; MDOUT=$(python "' + strPyPath + '" -d << BRKT_HTML\n' +
		strHTML + '\nBRKT_HTML); echo "$MDOUT" | pbcopy; echo "$MDOUT"';

	return app.doShellScript(strCMD);
}

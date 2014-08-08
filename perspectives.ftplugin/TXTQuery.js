//This code Copyright Robin Trew 2014
//FoldingText is Copyright Jesse Grosjean at HogBay Software

// Also includes some date-formatting functions from:
//	 * Date Format 1.2.3
//	 * (c) 2007-2009 Steven Levithan <stevenlevithan.com>
//	 * MIT license
//	(See further down)

// Version 0.4

function txtFLOWR(tree, param) {
	'use strict';

	var oReport;

function TextQuery(tree) {

	var strVersionNumber = "0.4",
		dctArgtFLWORs,
		lstPackList,
		varActiveDoc,
		lstFileStarts=[], //(sorted start positions [chars] in concat files)
		lngSourceFiles=1, //lstFilesStarts.length, cached for repeated use
		dctSources={}; //(keyed by start position, {name: url: line: start:})

	var	oSmallTime,
		DOLLAR= String.fromCharCode(36),
		CURLYDOLLAR = String.fromCharCode(123,36),
		dctCustomSettings = {},

		dctDefaultSources = {
			"collections": "~/Library/Application Support/Notational Velocity/project*",
			"docs": "~/Library/Application Support/Notational Velocity/inbox.txt",
			"filetypes": "txt,md,ft",
			"switches": "-maxdepth 1",
			"mtime": "14" // last modified n[smhdw] d is default (bash ind)
		},

		dctDefaultMenu = {
		"Done by date":{
			"sources":{
				"mtime": ["7"] // see Bash: man find
			},
			"title": "## Done (by date)",
			"for": "$items in //@done",
			"let": ["$date = fn:daypart($items@done)",
					"$project = $items@project"],
			"groupby": "$date",
			"orderby": "$date",
			"return": [
				"### {$date}",
				{
					"for": "$i in $items",
					"orderby": "$project",
					"return": "- {$i@text} {$i@tags}"
				},
				""
			]
		},
		"Grouped by tag III": {
			"title": "## Tags and their values",
			"for": "$tag in fn:tagSet()",
			"let": "$items = //@{$tag}",
			"orderby": "$tag",
			"return": [
				"### fn:sentence_case({$tag})",
				{
					"for": "$i in $items",
					"let": "$val = $i@{$tag}",
					"groupby": "$val",
					"orderby": "$val",
					"return": [
						"{$val}",
						{
							"for": "$j in $i",
							"return": "[{$j@file} line {$j@linenum}]({$j@link})\t- {$j}"
						},
						""
					]
				},
				""
			]
		},
		"Grouped by tag II": {
			"for": "$tag in fn:tagSet()",
			"let": "$items = //@{$tag}",
			"orderby": "$tag",
			"return": [
				"#### fn:sentence_case({$tag}) (fn:count($items))",
				{
					"for": "$i in $items",
					"let": "$val = $i@{$tag}",
					"orderby": "$val",
					"return": "{$val} - {$i}"
				},
				""
			]
		},
		"Grouped by tag": {
			"sources":{
				"collections": "~/Library/Application Support/Notational Velocity/project*",
				"docs": "~/Library/Application Support/Notational Velocity/inbox.txt",
				"filetypes": ["txt","md","ft"],
				"mtime": "42d", // only files last modified within ...
				"switches":"-maxdepth 1"
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
		},
		"Simple sort": {
			"title": "### Testing empty sort order",
			"for": "$line in //@type!=empty",
			"let": "$level = $line@priority",
			"orderby": "$level",
			"return": "- fn:sentence_case({$line@text}) {$level}"
		},
		"Grouped by any old tags": {
			"for": "$tag in fn:tagSet()",
			"let": "$lines = //@{$tag}",
			"return": [
				"### fn:sentence_case({$tag}) (fn:count($lines) items)",
				{
					"for": "$i in $lines",
					"let": "$value = $i@{$tag}",
					"groupby": "$value",
					"orderby": "$value",
					"return": [
						"\t{$value}",
						{
							"for": "$j in $i",
							"return": "\t\t- {$j}"
						},
						""
					]
				},
				""
			]
		},
		"Dates with priority subsections": {
			"title": "## Dates by priority",
			"for": "$line in //@type!=empty",
			"let": "$due = fn:daypart($line@due)",
			"groupby": "$due",
			"orderby": "$due",
			"return": [
				"### Due {$due}",
				"",
				{
					"for": "$item in $line",
					"let": "$level = $item@priority",
					"groupby": "$level",
					"orderby": "$level asc",
					"return": [
						"#### Priority ({$level})",
						{
							"for": "$i in $item",
							"let": "$time = fn:timepart($i@due)",
							"orderby": "$i@due",
							"return": "- {$time} {$i}"
						},
						""
					]
				},
				""
			]
		},
		"Grouped by due date and priority": {
			"for": "$line in //@priority and @due",
			"let": "$level = $line@priority, $due = fn:daypart($line@due)",
			"groupby": "$due, $level",
			"orderby": "$due, $level",
			"return": [
				"#### Due {$due} (Priority {$level})",
				{
					"for": "$i in $line",
					"return": "- fn:timepart({$i@due}) {$i}"
				},
				""
			]
		},
		"Due this week (with NVALT links)": {
			"title": "## This WEEK",
			"for": "$item in //@due <= {today + 7d}",
			"let": "$day = fn:daypart($item@due)",
			"groupby": "$day",
			"orderby": "$day",
			"return": [
				"### {$day}",
				{
					"for": "$i in $item",
					"orderby": "$i@due",
					"return": "- fn:timepart({$i@due}) [{$i}](nvalt://fn:encode_for_uri({$i}))"
				},
				""
			]
		},
		"Overdue with ftdoc links": {
			"title": "## This WEEK",
			"for": "$item in //@due < {now}",
			"let": "$day = fn:daypart($item@due)",
			"groupby": "$day",
			"orderby": "$day",
			"return": [
				"### fn:format_date({$day}, [FNn] [D] [MNn] [Y])",
				{
					"for": "$i in $item",
					"orderby": "$i@due",
					"return": "- fn:timepart({$i@due}) [{$i}]({$i@url})"
				},
				""
			]
		},
		"Due this week": {
			"title": "## This WEEK no links",
			"for": "$item in //@due <= {today + 7d}",
			"let": "$day = fn:daypart($item@due)",
			"groupby": "$day",
			"orderby": "$day",
			"return": [
				"### {$day}",
				{
					"for": "$i in $item",
					"orderby": "$i@due",
					"return": "- fn:timepart({$i@due}) {$i}"
				},
				""
			]
		},
		"Allocated time": {
			"title": "## Time Allocated",
			"for": "$head in /* intersect //@mins/ancestor::*",
			"let": "$lines = /{$head}//@mins",
			"return": [
				"### fn:upper_case({$head}): total fn:sum($lines@mins)m",
				{
					"for": "$i in $lines",
					"return": "- {$i} ({$i@mins}m)"
				},
				""
			]
		},
		"Tagged lines - grouped by tags": {
			"for": "$tag in fn:tagSet()",
			"return": [
				"## fn:sentence_case({$tag})",
				{
					"for": "$node in //@{$tag}",
					"orderby": "$node@{$tag} asc",
					"return": "{$node@$tag} - {$node}"
				},
				""
			]
		},
		"Grouped by any priority levels found": {
			"title": "### Priorities",
			"for": "$line in //@priority",
			"let": "$level = $line@priority",
			"groupby": "$level",
			"orderby": "$level",
			"return": [
				"### Priority {$level} [fn:sum($line@priority)]",
				{
					"for": "$node in $line",
					"return": "- {$node}"
				},
				""
			]
		},
		"All Nodes simplest sort": {
			"for": "$line in //@type!=empty",
			"let": "$text=$line",
			"orderby": "$text desc",
			"return": "- {$text}"
		},
		"Sorted list with NOTES": {
			"for": "$line in //@type=unordered",
			"orderby": "$line desc",
			"return": [
				"- {$line}{$line@note}"
			]
		},
		"Numbers in sorted in sequence": {
			"for": "$num in (10,9,234, 1,2,    5   ,6,7,3,4,8,9)",
			"orderby": "$num asc",
			"return": "- {$num}"
		},
		"Tags in sequence": {
			"for": "$tag in fn:tagSet()",
			"let": "$all = //@{$tag}",
			"return": [
				"#### fn:sentence_case({$tag})  (fn:count($all))",
				{
					"for": "$i in $all",
					"return": "- {$i}"
				},
				""
			]
		},

		"Tags in document": {
			"for": "$tag in fn:tagSet()",
			"orderby": "$tag",
			"return": "- fn:sentence_case({$tag})"
		},
		"Grouped by due date": {
			"for": "$line in //@due",
			"let": "$due = $line@due",
			"groupby": "$due",
			"orderby": "$due",
			"return": [
				"## Due {$due}",
				{
					"for": "$l in $line",
					"return": "- {$l@parent} → {$l}"
				},
				""
			]
		}
	},

	dctDefaultSettings = {
		"sources": dctDefaultSources,
		"menu":dctDefaultMenu,
		"queue":[]
	},

	dctViewFn = {
		"format_date":function format_date(varArg) {
			var varDate, strDate, strMask;
			if (varArg instanceof Array) {
				if (varArg.length > 1) {
					strDate = varArg[0];
					if (!oSmallTime) oSmallTime = new SmallTime();
					varDate = oSmallTime.readDatePhrase(strDate);
					if (! isNaN(varDate)) {
						strMask = xQueryPicToDateJSMask(varArg[1]);
						strDate = varDate.format(strMask);
					}
				}
			} else {
				strDate = varArg.toString();
			}
			return strDate;
		},
		"timepart" : function timepart(varArg) {
			//last five characters of yyyy-mm-dd hh:mm
			var varValue = varArg.toString(),
				strTime = varValue.slice(11);
			if (strTime) {
				return "**" + strTime + "**";
			} else {
				return "";
			}
		},

		"daypart" : function daypart(varArg) {
			//first 10 characters of yyyy-mm-dd hh:mm
			var varValue = varArg.toString();
			return varValue.slice(0, 10);
		},

		"tagSet":function tagSet() {
			tree.ensureClassified();
			return tree.tags(true);
		},
		"sentence_case": function sentence_case(strAny) {
			var varValue = strAny.toString(), strSentence="",
			lngChars = varValue.length;
			if (lngChars) {
				strSentence = varValue[0].toUpperCase();
				if (lngChars > 1) {
					strSentence += varValue.slice(1).toLowerCase();
				}
			}
			return strSentence;
		},
		"upper_case": function upper_case(strAny) {
			var varValue = strAny.toString();
			return varValue.toUpperCase();
		},
		"lower_case": function lower_case(strAny) {
			var varValue = strAny.toString();
			return varValue.toLowerCase();
		},
		"count": function count(varList, dctNames) {
			var varValue, lstNodes;

			if (varList instanceof Array) {
				return varList.length.toString();
			} else {
				varValue = dctNames[varList];
				if (varValue !== undefined) {
					if (varValue instanceof Array) {
						return varValue.length.toString();
					} else {
						return varList;
					}
				} else {
					varList = tree.evaluateNodePath(varList);
					if (lstNodes instanceof Array) {
						return lstNodes.length.toString();
					} else {
						return varList;
					}
				}
			}
		},

		"sum" : function sum(varList, dctNames) {

			var lstNums = [];
			function isNum(x) {return !isNaN(x);}

			//Normalize to a a list of any numbers
			if (typeof(varList) == "string") {
				lstNums = readAsList(varList).filter(isNum);
			}
			if (varList instanceof Array) {
				lstNums = varList.filter(isNum);
			}

			//and sum any data
			if (lstNums.length) {
				return lstNums.reduce(
					function(a, b) {
						return (Number(a) + Number(b)).toString();
					}
				);
			} else {
				return "0";
			}
		},

		"substring" : function substring(varArgs) {
			//N chars (if specified) from 1-based lngFrom (or rest)
			var strShort ="", lngFrom=0, lngN, lngParts;
			if (varArgs instanceof Array) {
				lngParts = varArgs.length;
				if (lngParts) {
					strShort = varArgs[0];
					if (lngParts > 1) lngFrom = parseInt(varArgs[1], 10);
					if (lngParts > 2) lngN = parseInt(varArgs[1], 10);
					strShort = strShort.slice(lngFrom-1, lngN);
				}
				return strShort;
			} else {
				return varArgs;
			}
		},

		"if_empty" : function if_empty(varArgs) {
			//return string if head of list not empty
			var varValue, lngParts, strResult='';
			if (varArgs instanceof Array) {
				lngParts = varArgs.length;
				if (lngParts) {
					if (varArgs[0]) {
						if (lngParts > 2) strResult = varArgs[2];
					} else {
						if (lngParts > 1) strResult = varArgs[1];
					}
				}
				return strResult;
			} else {
				return varArgs;
			}
		},

		"encode_for_uri" : function encode_for_uri(varArg) {
			var varValue = varArg.toString();
			return encodeURIComponent(varValue);
		},
		"bracket" : function bracket(varArg) {
			var varValue = varArg.toString();
			if (varValue) {
				return "(" + varValue + ")";
			} else {
				return "";
			}
		}
	};

	//// DATE FORMAT BY STEVEN LEVITHAN BEGINS

		/*
	 * Date Format 1.2.3
	 * (c) 2007-2009 Steven Levithan <stevenlevithan.com>
	 * MIT license
	 *
	 * Includes enhancements by Scott Trenda <scott.trenda.net>
	 * and Kris Kowal <cixar.com/~kris.kowal/>
	 *
	 * Accepts a date, a mask, or a date and a mask.
	 * Returns a formatted version of the given date.
	 * The date defaults to the current date/time.
	 * The mask defaults to dateFormat.masks.default.
	 */

	var dateFormat = (function () {
		var	token = /d{1,4}|m{1,4}|yy(?:yy)?|([HhMsTt])\1?|[LloSZ]|"[^"]*"|'[^']*'/g,
			timezone = /\b(?:[PMCEA][SDP]T|(?:Pacific|Mountain|Central|Eastern|Atlantic) (?:Standard|Daylight|Prevailing) Time|(?:GMT|UTC)(?:[\-+]\d{4})?)\b/g,
			timezoneClip = /[^\-+\dA-Z]/g,
			pad = function (val, len) {
				val = String(val);
				len = len || 2;
				while (val.length < len) {
					val = '0' + val;
				}
				return val;
			};

		// Regexes and supporting functions are cached through closure
		return function (date, mask, utc) {
			var dF = dateFormat;

			// You can't provide utc if you skip other args (use the 'UTC:' mask prefix)
			if (arguments.length === 1 && Object.prototype.toString.call(date) === '[object String]' && !/\d/.test(date)) {
				mask = date;
				date = undefined;
			}

			// Passing date through Date applies Date.parse, if necessary
			date = date ? new Date(date) : new Date();
			if (isNaN(date)) {
				throw new SyntaxError('invalid date');
			}

			mask = String(dF.masks[mask] || mask || dF.masks['default']);

			// Allow setting the utc argument via the mask
			if (mask.slice(0, 4) === 'UTC:') {
				mask = mask.slice(4);
				utc = true;
			}

			var	_ = utc ? 'getUTC' : 'get',
				d = date[_ + 'Date'](),
				D = date[_ + 'Day'](),
				m = date[_ + 'Month'](),
				y = date[_ + 'FullYear'](),
				H = date[_ + 'Hours'](),
				M = date[_ + 'Minutes'](),
				s = date[_ + 'Seconds'](),
				L = date[_ + 'Milliseconds'](),
				o = utc ? 0 : date.getTimezoneOffset(),
				flags = {
					d:    d,
					dd:   pad(d),
					ddd:  dF.i18n.dayNames[D],
					dddd: dF.i18n.dayNames[D + 7],
					m:    m + 1,
					mm:   pad(m + 1),
					mmm:  dF.i18n.monthNames[m],
					mmmm: dF.i18n.monthNames[m + 12],
					yy:   String(y).slice(2),
					yyyy: y,
					h:    H % 12 || 12,
					hh:   pad(H % 12 || 12),
					H:    H,
					HH:   pad(H),
					M:    M,
					MM:   pad(M),
					s:    s,
					ss:   pad(s),
					l:    pad(L, 3),
					L:    pad((L > 99) ? Math.round(L / 10) : L),
					t:    ((H < 12) ? 'a':'p'),
					tt:   ((H < 12) ? 'am':'pm'),
					T:    ((H < 12) ? 'A':'P'),
					TT:   ((H < 12) ? 'AM':'PM'),
					Z:    (utc ? 'UTC' : (String(date).match(timezone) || ['']).pop().replace(timezoneClip, '')),
					o:    ((o > 0) ? '-':'+') + pad(Math.floor(Math.abs(o) / 60) * 100 + Math.abs(o) % 60, 4),
					S:    ['th', 'st', 'nd', 'rd'][(d % 10 > 3) ? 0:(d % 100 - d % 10 !== 10) * d % 10]
				};

			return mask.replace(token, function ($0) {
				return $0 in flags ? flags[$0] : $0.slice(1, $0.length - 1);
			});
		};
	})();

	// Some common format strings
	dateFormat.masks = {
		'default':      'ddd mmm dd yyyy HH:MM:ss',
		shortDate:      'm/d/yy',
		mediumDate:     'mmm d, yyyy',
		longDate:       'mmmm d, yyyy',
		fullDate:       'dddd, mmmm d, yyyy',
		shortTime:      'h:MM TT',
		mediumTime:     'h:MM:ss TT',
		longTime:       'h:MM:ss TT Z',
		isoDate:        'yyyy-mm-dd',
		isoTime:        'HH:MM:ss',
		isoDateTime:    'yyyy-mm-dd\'T\'HH:MM:ss',
		isoUtcDateTime: 'UTC:yyyy-mm-dd\'T\'HH:MM:ss\'Z\''
	};

	// Internationalization strings
	dateFormat.i18n = {
		dayNames: [
			'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
			'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
		],
		monthNames: [
			'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
			'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'
		]
	};

	// For convenience...
	Date.prototype.format = function (mask, utc) {
		return dateFormat(this, mask, utc);
	};

	//// DATE FORMAT BY STEVEN LEVITHAN ENDS (SEE LICENSE ABOVE)

	function xQueryPicToDateJSMask(strPic) {
		var lstPic=[], lstParts, strSubMask, strLiteral;
		strPic.split('[').forEach(function (strPart) {
			lstParts=strPart.split(']');
			if (lstParts.length > 1) {
				strSubMask = picTrans(lstParts[0]);
				strLiteral=lstParts[1];
				if (strLiteral) strSubMask += ('\'' + strLiteral + '\'');
				lstPic.push(strSubMask );
			}
		});
		return lstPic.join('');
	}

	function picTrans(strPic) {
		// from xquery date picture conventions to those of FT date.js
		var lngChars=strPic.length,strHead, strNext='', strMask='';
		if (lngChars) {
			strHead=strPic.charAt(0);
			if (lngChars > 1) strNext=strPic.charAt(1);
			switch (strHead) {
				case 'Y':
					strMask='yyyy';
					break;
				case 'M':
					if ((strNext !== 'N') && (strNext !== 'n')) strMask='mm';
					else {
						if (strPic.indexOf(',') !== -1) strMask='mmm';
						else strMask='mmmm';
					}
					break;
				case 'D':
					if (strNext !== '1') strMask = 'dd';
					else strMask = 'd';
					if (strPic.slice(-1) == 'o') strMask += 'S';
					break;
				case 'F':
					if (strPic.indexOf(',') !== -1) strMask='ddd';
					else strMask='dddd';
					break;
				case 'H':
					if (strNext !== '1') strMask='HH';
					else strMask='H';
					break;
				case 'h':
					if (strNext !== '1') strMask='hh';
					else strMask='h';
					break;
				case 'P':
					if (strNext !== '1') {
						if (strNext !== 'N') strMask='tt';
						else strMask='TT';
					} else strMask='t';
					break;
				case 'm':
					if (strNext !== '1') strMask='MM';
					else strMask='M';
					break;
				case 's':
					if (strNext !== '1') strMask='ss';
					else strMask='s';
					break;
				case 'f':
					strMask = 'l';
					break;
				case 'Z':
				case 'z':
					strMask='Z';
					break;
				default:
					strMask='';
			}
		}
		return strMask;
	}

	this.translateView = function () {
		var dctView, dctFLWOR, key, strReport = "", strTitle;
		if (dctArgtFLWORs === undefined || dctArgtFLWORs == {}) {
				dctArgtFLWORs = dctDefaultMenu;
		}
		prepareSourceList();
		for (var strKey in dctArgtFLWORs) {
			dctView = dctArgtFLWORs[strKey];
			strReport += buildView(dctView, strKey);

			//break;
		}
		console.log(strReport);
		return strReport;
	};

	function Group(dctParent) {
		this.parent = dctParent;
		this.emptylast = true;
		this.for = [];
		this.let = [];
		//this.where = []; useful ? haven"t decided or implemented
		this.groupby = [];
		this.orderby = [];
		this.order = [];
		this.groups = {};
		this.return = [];
		this.init(dctParent);
	}

	Group.prototype.init = function(dctParent) {
		var strType="";
		if (dctParent !== null) {
			if (dctParent.groupby.length) {
				this.groupby = dctParent.groupby.slice(1);
			}
			if (dctParent.orderby.length) {
				this.orderby = dctParent.orderby.slice(1);
			}
			//and inherit any dollar-prefixed names which map to strings
			for (var strKey in dctParent) {
				if (strKey.charAt(0) == DOLLAR) {
					strType = typeof dctParent[strKey];
					if (strType == "string" || strType == "function") {
						this[strKey] = dctParent[strKey];
					}
				}
			}
		}
	};

	function prepareSourceList() {
		// If we are querying several files in a temporary
		// concatenation, where does each file start in the snowball ?
		//lstPackList → lstFileStarts -- > dctSources;
		//needed to file-based line numbers urls, char posns etc
		//for particular lines within a concatenated snowball
		if (lstPackList === undefined || lstPackList == []) {
			lstPackList = ['', 0, 0];
		}
		var lngParts = lstPackList.length, lngFiles = lngParts/3,
			strCharNum, strLineNum, strPath, strName, strURL='';
		for (var i=(lngFiles*3)-1; i>=0; i-=3) {
			strLineNum = lstPackList[i];
			strCharNum = lstPackList[i-1];
			strPath = lstPackList[i-2];
			if (strPath) {
				strName = strPath.split('/').pop();
				strURL = 'ftdoc://' + encodeURI(strPath);
			} else {
				strName = varActiveDoc || "Active document";
			}
			dctSources[strCharNum] = {"start":parseInt(strCharNum, 10),
				"url":strURL, "name":strName,
				"line":parseInt(strLineNum,10)};
		}

		// and initialise the sorted index of start positions
		lstFileStarts = [];
		Object.keys(dctSources).forEach(function (varKey) {
			lstFileStarts.push(parseInt(varKey, 10));
		});
		// sort file start positions numerically
		lngSourceFiles = lstFileStarts.length;
		if (lngSourceFiles > 1) {
			lstFileStarts.sort(function (a, b) {return a - b;});
		}
	}

	//dctFLWOR is assumed to contain all the information needed for
	//expansion into a grouping tree
	function groupedFLWOR(dctFLWOR) {

		var rgxFnArgs = /fn:(\w+)\(([^\)]+)\)/,
			oMatch, strFnLabel,
			blnDoubleFn = false, strFnTemplate,
			varGetValue, fnGetValue,
			dctGrouped, dctChild, dctOrder, dctSubTree,
			lstFor, lstNodes, lstStream,
			varGroupbyHead,
			strValue, strForName,
			lngGroupLevels = dctFLWOR.groupby.length,
			lngSorts, fnSort;

		if (lngGroupLevels) {
			dctGrouped = clone(dctFLWOR);
			lstFor = dctGrouped.for;
			strForName = lstFor[0];
			lstNodes = dctGrouped[strForName];
			//Get the HEAD function name
			varGroupbyHead = dctGrouped.groupby[0];
			lngSorts = dctGrouped.orderby.length;
			//The TAIL will be passed down to child groups

			//and get a reference to the corresponding function

			fnGetValue = dctGrouped[varGroupbyHead];
			//Using it to derive values and allocate elements to new
			//or existing child FLWOR buckets

			dctGrouped[varGroupbyHead] = dctGrouped.order;

			lstNodes.forEach(function(oNode) {

				//Derive a triage value for the current node,
				strValue = fnGetValue(oNode);

				//and check whether we have seen this value before
				if (dctGrouped.order.indexOf(strValue) !== -1) {
					//If we have, place it in the existing subgroup
					dctGrouped.groups[strValue][strForName].push(oNode);
				} else {
					//if this is a new value
					//first push it onto the order list
					//for later sorting
					dctGrouped.order.push(strValue);
					//and then create a new subgroup
					dctChild = new Group(dctGrouped);

					//Pass down the Return value here
					//so that it reaches the grouping leaves.
					//RETURN is not automatically transmitted at create time
					//because GROUPing recursion is a bit different from
					//nested  RETURN recursion
					dctChild.return = dctGrouped.return;

					//keyed in the parent nodes group object
					//by the value for which it collects nodes
					dctGrouped.groups[strValue] = dctChild;

					//begin with the minimum preparation of the child
					//node
					//i.e. enable it to receive elements of its
					//sequence
					dctChild.for = dctGrouped.for;
					dctChild[strForName] = [oNode];
					dctChild[varGroupbyHead] = strValue;
					//and push a reference to the current node
					//into its sequence list
				}
			});

			//Once we have allocated nodes to groups
			//return to prepare each group for writing out
			//(including by recursively developing any subgroups)
			//either now or at write time, we will also need to
			//recursively develop any nested return FLWORs

			//APPLY ANY SORTING INSTRUCTIONS
			if (lngSorts) {
				dctOrder = dctGrouped.orderby[0];
				lstStream = dctGrouped[dctOrder.stream];
				if (lstStream !== undefined) {
					sortNodes(lstStream, dctOrder.ascend,
						dctOrder.attrib, dctOrder.emptyvalue);
				}
			}

			//then, if there is any subgrouping to be done
			//iterate through the children and recurse for further grouping
			if (lngGroupLevels > 1) {
				dctGrouped.order.forEach(function(strValue) {
					dctChild = dctGrouped.groups[strValue];
					dctSubTree = groupedFLWOR(dctChild);
				});
			}

		} else {
			dctGrouped = dctFLWOR;
		}

		return dctGrouped;
	}

	//Make a copy of an object (to avoid destructive update)
	function clone(obj) {
		var dctTarget = {};
		for (var i in obj) {
			if (obj.hasOwnProperty(i)) dctTarget[i] = obj[i];
		}
		return dctTarget;
	}

	function viewTree(dctView, dctContext) {
		var dctFLWOR = new Group(null),
			varDecln = dctView["declare"],
			varFor = dctView["for"],
			varLet = dctView["let"],
			varOrder = dctView["orderby"],
			varGroup = dctView["groupby"],
			varReturn = dctView["return"],
			dctSeries, dctOrder, varEmptyValue,
			varLast,
			strAttrib, strExpr, strOption,
			lstSeries, lstSymbols, lngParts, i,
			strKey, blnAsc, lstParts, blnEmptyLast,
			dctGrouped = {};

		//Inherit any context of existing bindings

		for (strKey in dctContext) {
			if (strKey.charAt(0) == DOLLAR) {
				dctFLWOR[strKey] = dctContext[strKey];
			}
		}

		//SET ANY GLOBAL PREFERENCE FOR SORTING EMPTY VALUES
		if (varDecln) {
			if (typeof(varDecln) == "string") {
				varDecln = [varDecln];
			}
			if (varDecln instanceof Array) {
				varDecln.forEach(function (strDecln) {
					lstParts = strDecln.trim().split(/\s+/);
					lngParts = lstParts.length;
					if (lngParts) {
						varEmptyValue =
							lstParts[lngParts -1].toUpperCase();
						if (varEmptyValue) {
							if (varEmptyValue == "LEAST") {
								dctFLWOR["emptylast"] = false;
							} else if (varEmptyValue.indexOf("GREAT") === 0) {
								dctFLWOR["emptylast"] = true;
							}
						}
					}
				});
			} else {
				//unexpected -- raise an error
			}
		}

		//ADD ANY SORTING REQUESTS TO THE PROCESSING CONTEXT
		//DEFINE DOLLARLET NAMES AS FUNCTIONS OF TUPLE STREAM ELEMENTS
		if (varLet) {
			if (typeof(varLet) == "string") {
				varLet = varLet.trim().split(/\s*,\s*/);
			}
			if (varLet instanceof Array) {
				varLet.forEach(function (strExpr) {
					addBinding(strExpr, dctFLWOR);
				});
			} else {
				//unexpected -- raise an error
			}
		}

		if (varOrder) {
			if (typeof(varOrder) == "string") {
				varOrder = varOrder.trim().split(/\s*,\s*/);
			}
			if (varOrder instanceof Array) {
				varOrder.forEach(function (strSeq) {
					//First split on space to find any DESC etc

					blnAsc = true;
					lstParts = strSeq.split(/\s+/);
					lngParts = lstParts.length;
					if (lngParts > 1) {
						blnAsc = lstParts[1].toUpperCase().indexOf(
							"DESC") !== 0;
						varLast = lstParts[lngParts -1].toUpperCase();
						//overriding sort order of empty elements ?
						if (varLast.indexOf("LEAST") ===0) {
							dctFLWOR.emptylast = false;
						} else if (varLast.indexOf("GREAT") === 0) {
							dctFLWOR.emptylast = true;
						}
					}

					//Then split on @ to find a specific sort field (for nodes)
					if (lngParts) {
						strExpr = lstParts[0];
						if (strExpr.indexOf(DOLLAR) !== -1) {
							strExpr = expandDollars(strExpr, dctFLWOR);
						}
						lstParts = strExpr.split(/\s*\@\s*/);

						dctOrder = {};
						dctOrder["stream"] = lstParts[0];
						dctOrder["ascend"] = blnAsc;
						blnEmptyLast = dctFLWOR.emptylast;
						if ((blnEmptyLast && blnAsc) ||
								(!blnEmptyLast && !blnAsc)) {
							dctOrder["emptyvalue"] =
								Number.POSITIVE_INFINITY;
						} else {
							dctOrder["emptyvalue"] =
								Number.NEGATIVE_INFINITY;
						}

						if (lstParts.length > 1) {
							strAttrib = lstParts[1];
							if (strAttrib.indexOf(DOLLAR) !== -1) {
								strAttrib = expandDollars(
									strAttrib, dctContext);
							}
							dctOrder["attrib"] = strAttrib;
						} else {
							if (typeof dctFLWOR[strExpr] !== "function") {
								dctOrder["attrib"] = "";
							} else {
								dctOrder["attrib"] = dctFLWOR[strExpr];
							}
						}
						dctFLWOR.orderby.push(dctOrder);
					}
				});
			} else {
				//unexpected -- raise an error
			}
		}

		//TRANSLATE ANY "FOR" STRINGS
		dctSeries = tupleStreamNames(varFor, dctFLWOR);
		lstSymbols = dctSeries["symbols"]; //dollar-prefixed names
		lstSeries = dctSeries["series"];  //and the series themselves

		lngParts = lstSymbols.length;
		if (lngParts > 0) {
			//AND INITIALISE THE TOP LEVEL FLWOR NODE

			//The series names are top level keys in the dictionary
			dctFLWOR.for = lstSymbols;
			for (i=0; i<lngParts; i++) {
				dctFLWOR[lstSymbols[i]] = lstSeries[i];
			}

			//GET THE MAIN SERIES OF ENTITIES (OUTER FOR LOOP)
			strKey = lastItem(dctFLWOR["for"]);

			//Normalise any RETURN section
			if (varReturn) {
				if (typeof(varReturn) == "string") {
					varReturn = varReturn.split("\n");
				}
			}

			if (varReturn instanceof Array) {
				dctFLWOR.return = varReturn;
			} else {
				//unexpected, raise error
			}

			//AND EXPAND THE FLWOR NODE TO A -TREE- IF ANY GROUPING
			//IS REQUIRED

			if (varGroup) { //ADD SUB-GROUP CHILDREN TO dctFLWOR

				if (typeof(varGroup) == "string") {
					varGroup = varGroup.trim().split(/\s*,\s*/);
				}

				//should by now be an array of grouping function labels
				if (varGroup instanceof Array) {
					varGroup.forEach(function (strExpr) {
						dctFLWOR["groupby"].push(strExpr);
					});
				} else {
					//unexpected -- raise an error
				}
				dctGrouped = groupedFLWOR(dctFLWOR);

			} else {
				dctGrouped = dctFLWOR;
			}

		} else dctGrouped = dctFLWOR; //no FOR sequence ...

		return dctGrouped;
	}

	function tupleStreamNames(varFor, dctNames) {
		var rgxFnArgs = /^fn:(\w+)\((.*)\)/,
			rgxIsPath = /^[\/\()]/,
			dctSort, oMatch,
			lstSeries = [], lstSymbols = [],
			lstParts, lstOrderBy, lstNodes,
			strFn, strArg, strFor, strIn,
			strExpanded, strPath,
			i, j;

		//Convert from string to array, if necessary
		if (varFor) {
			if (typeof(varFor) == "string") {
				varFor = [varFor];
			}

			if (varFor instanceof Array) {
				varFor.forEach(function (strExpr) {
					//separate symbol from series expression
					lstParts = strExpr.trim().split(/\s+in\s+/);
					if (lstParts.length > 1) {

						//RECORD A DOLLARFOR SYMBOL
						strFor = lstParts[0];
						lstSymbols.push(strFor);

						strIn = lstParts[1];

						//A dollared name already bound in this context ?
						lstNodes = dctNames[strIn];
						if (lstNodes) {
							if (!(lstNodes instanceof Array)) {
								if (typeof lstNodes == "string") {
									if (lstNodes.indexOf(DOLLAR) !== -1) {
										lstNodes = expandDollars(
											lstNodes, dctNames);
									}
									if (lstNodes.indexOf("{") !== -1) {
										if (! oSmallTime ) {
											oSmallTime = new SmallTime();
										}
										lstNodes =
											oSmallTime.translatePathDates(
												strPath);
									}
								}
								lstNodes = tree.evaluateNodePath(lstNodes);
							}
							lstSeries.push(lstNodes);
						} else {
							//Expand any embedded DOLLARnames
							if (strIn.indexOf(DOLLAR) !== -1) {
								strExpanded = expandDollars(
									strIn, dctNames);
							} else {
								strExpanded = strIn;
							}
							if (rgxIsPath.exec(strExpanded) !== null) {
								strExpanded = makeLine(strExpanded, dctNames);
								lstNodes = tree.evaluateNodePath(strExpanded);
								if (lstNodes.length) {
									lstSeries.push(lstNodes);
								} else {
									lstSeries.push(
										readAsList(strExpanded));
								}

							//A FUNCTION TO EVALUATE ?
							} else if (strExpanded.slice(0,3) == "fn:") {
								oMatch = rgxFnArgs.exec(strExpanded);
								if (oMatch !== null) {
									strFn = oMatch[1];
									strArg = oMatch[2];
									lstSeries.push(
										dctViewFn[strFn](strArg));
								} else {
									//ill-formed ? -- raise error
								}
							} else {
								//not a path - some other kind of list ?
								lstSeries.push(readAsList(strExpanded));
							}
						}

					} else {
						//unexpected -- raise an error
					}
				});
			} else {
				//unexpected -- raise an error

			}
		}
		//sorting required ?

		lstOrderBy = dctNames.orderby;

		for (i=lstOrderBy.length; i--;) {
			dctSort = lstOrderBy[i];
			for (j=lstSeries.length; j--;) {
				sortNodes(lstSeries[j], dctSort.ascend, dctSort.attrib,
					dctSort.emptyvalue);
			}
		}
		return {"symbols":lstSymbols, "series":lstSeries};
	}

	function treeString(dctFLWOR) {
		var strLines = dctFLWOR.title,
			lstGroupOrder, dctGroups,
			dctSubFLWOR, dctSubSubFLWOR,
			strFor = dctFLWOR.for[0],
			varValues = dctFLWOR[strFor],
			lngGroupby = dctFLWOR.groupby.length;

			if (strLines === undefined) {
				strLines = "";
			} else {
				strLines += "\n\n";
			}

			//traverse across lowest level groups if there are any
			if (lngGroupby) {
				dctGroups = dctFLWOR.groups;
				lstGroupOrder = dctFLWOR.order;
				if (lngGroupby > 1) {
					//Still some subgrouping to do - recurse
					lstGroupOrder.forEach(function(strKey) {
						strLines += treeString(dctGroups[strKey]);
					});
				} else {
					//Fully grouped here, we can write out
					//lstGroupOrder.sort(); //SORTING PLACE
					lstGroupOrder.forEach(function(strKey) {
						dctSubFLWOR = dctGroups[strKey];
						dctSubFLWOR.return.forEach(function(varExpr) {
							if (typeof varExpr == "string") {
								if (varExpr) {
									strLines += makeLine(varExpr, dctSubFLWOR);
								} else {
									strLines += "\n";
								}
							} else {
								dctSubSubFLWOR = viewTree(varExpr, dctSubFLWOR);
								strLines += treeString(dctSubSubFLWOR);
							}
						});
					});
				}
			} else { //this is a group leaf – translate and output
					//the whole Return once for each DOLLARFOR value

				if (varValues instanceof Array) {
					//SORTING PLACE sort on specified attrib
					//and in specified direction
					dctSubFLWOR = clone(dctFLWOR);
					varValues.forEach(function (varForValue) {
						dctSubFLWOR[strFor] = varForValue;

						strLines += treeString(dctSubFLWOR);
					});
				} else {
					dctFLWOR.return.forEach(function(varExpr) {
						if (typeof varExpr == "string") {
							if (varExpr) {
								strLines += makeLine(varExpr, dctFLWOR);
							} else {
								strLines += "\n";
							}
						} else {
							dctSubFLWOR = viewTree(varExpr, dctFLWOR);
							strLines += treeString(dctSubFLWOR);
						}
					});
				}
			}

		return strLines;
	}

	function lastItem(lst) {
		return lst[lst.length-1];
	}

	//Sorting terminal sequences, usually node objects, but potentially
	//atomic
	function sortNodes(lstNodes, blnAsc, varSortBy, cEmptyValue) {

		//some attribs have a predictable type
		//for @tag(values) - check whether the whole harvest is numeric
		var fnPrimer;

		blnAsc = (blnAsc !== undefined ? blnAsc : true);

		if (varSortBy === undefined) {varSortBy = "";}
		if (typeof varSortBy !== "function") {
			varSortBy = (varSortBy !== "" ? varSortBy : "text");

			if (["level", "index"].indexOf(varSortBy) !== -1) {
				fnPrimer = parseInt;
			} else if (allNum(lstNodes)) {
				fnPrimer = parseFloat;
			} else {
				fnPrimer = function(a) {
					if (a) {
						return a.toUpperCase();
					} else {
						return cEmptyValue;
					}
				};
			}

			return lstNodes.sort(sortByAttrib(
				varSortBy, blnAsc, getAttrib, fnPrimer));
		} else {
			fnPrimer = function(a) {
				if (a) {
					return a.toUpperCase();
				} else {
					return cEmptyValue;
				}
			};
			return lstNodes.sort(sortByFn(varSortBy, blnAsc, fnPrimer));
		}
	}

	function sortByAttrib(field, reverse, fnGet, primer) {
		var key = primer ?
			function(x) {return primer(fnGet(x,field));} :
			function(x) {return fnGet(x,field);};

		reverse = [-1, 1][+!!reverse];

		return function (a, b) {
			return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
		};
	}

	function sortByFn(fnGet, reverse, primer) {
		var key = primer ?
			function(x) {return primer(fnGet(x));} :
			function(x) {return fnGet(x);};

		reverse = [-1, 1][+!!reverse];

		return function (a, b) {
			return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
		};
	}

	//SORTING GROUP KEYS (String, Numeric, ISO Date string)
	//Apply a numeric sort function if no values NaN,
	//otherwise normalise case and sort as strings
	function sortKeys(lstKeys, blnAsc) {
		var fnSort;

		if (allNum(lstKeys)) {
			if (blnAsc) {
				fnSort = function(a, b) {return a - b;};
			} else {
				fnSort = function(a, b) {return b - a;};
			}
		} else {
			if (blnAsc) {
				fnSort = function (a, b) {
					return a.toLowerCase().localeCompare(b.toLowerCase());};
			} else {
				fnSort = function (a, b) {
					return b.toLowerCase().localeCompare(a.toLowerCase());};
			}
		}
		return lstKeys.sort(fnSort);
	}

	//Are all the values in this array numeric ?
	function allNum(lst) {
		var i, lng = lst.length, blnNum = true;
		if (lng > 0) {
			for (i=0; i < lng; i++) {
				if (isNaN(lst[i])) {
					blnNum = false;
					break;
				}
			}
		}
		return blnNum;
	}

	//evaluate a string or FLWOR dictionary in a FLWOR line return list
	function makeLine(varLine, dctNames) {
		var strType = typeof(varLine), strExpanded, strLines;

		if (strType == "string") {
			if (varLine.indexOf(DOLLAR) !== -1) {
				strExpanded = expandDollars(varLine, dctNames);
			} else {
				strExpanded = varLine;
			}
			if (strExpanded && (strExpanded !== "")) {
				if (strExpanded.indexOf("{") !== -1) {
					if (! oSmallTime) oSmallTime = new SmallTime();
					strExpanded = oSmallTime.translatePathDates(strExpanded);
				}
				if (strExpanded.indexOf("fn:") !== -1) {
					strLines = expandFns(strExpanded, dctNames);
				} else {
					strLines = strExpanded;
				}
			}

		} else if (strType == "object") {

			//recurse with a child FLWOR to get a string
			strLines = treeString(varLine, dctNames);
		}
		return strLines + "\n";
	}

	function readAsList(strList) {
		var rgxList = /[\(\[](.*)[\]\)]/,
			oMatch = rgxList.exec(strList), strContent,
			lstContent = [];

		if (oMatch !== null) {
			strContent = oMatch[1];
			lstContent = strContent.trim().split(/\s*,\s*/);
		} else {
			lstContent = [];
		}
		return lstContent;
	}

	//Associate a symbol with a composed function
	//(for deriving values as functions of elements in the tuple stream)
	function addBinding(strExpr, dctFLWOR) {
		//for the moment, default to adding a function which
		//wraps getAttrib to retrieve a particular attribute from
		//a node

		var lstParts = strExpr.trim().split(/\s*\=\s*/),
			rgxIsPath = /^[\/\()]/,
			rgxFnArgs = /fn:(\w+)\(([^\)]+)\)/,
			oMatch, lstFnNames, lstFns, fnComplex,
			strArg,
			strKey, strValue, strAttrib;

		if (lstParts.length > 1) {
			strKey = lstParts[0];
			strValue = lstParts[1];

			if (rgxIsPath.exec(strValue)) {
				//bind to a regex path
				dctFLWOR[strKey] = strValue;
			} else {

				if (strValue.indexOf("fn:") !== -1) {
					lstFnNames = fnNestingList(strValue);
					if (lstFnNames.length) {
						strArg = lstFnNames.shift();
						lstFns = [];
						for (var i = lstFnNames.length; i--;) {
							lstFns.push(dctViewFn[lstFnNames[i]]);
						}

						// compose a nested function
						fnComplex = fnComposed(lstFns);

						lstParts = strArg.split(/\s*\@\s*/);
						strAttrib = lstParts[1];
						dctFLWOR[strKey] = function () {
							return fnComplex(getAttrib(arguments[0], strAttrib));
						};
					}
				} else {
					//bind to a simple function which fetches
					//an attribute value from a node
					lstParts = strValue.split(/\s*\@\s*/);
					if (lstParts.length) strAttrib = lstParts[1];
					if (strAttrib) {
						if (strAttrib.indexOf(CURLYDOLLAR) === 0) {
							strAttrib = expandDollars(strAttrib, dctFLWOR);
						}
					}

					dctFLWOR[strKey] = function () {
						return getAttrib(arguments[0], strAttrib);
					};
				}
			}
		}
	}

	function fnNestingList(strExpr) {
		//look for innermost function
		//function name + bracket pair enclosing
		//a bracketless argument
		var rgxDeepest = /fn:([^\(]+)\(([^\(\)]*)\)/,
			oMatch = rgxDeepest.exec(strExpr),
			lstArgFns=[], strRest;

		strRest = strExpr.trim();
		if (strRest && oMatch) {
			//first item in output list is the argument,
			lstArgFns.push(oMatch[2]);

			//then harvest functions in order of nested execution
			while(strRest && oMatch) {
				lstArgFns.push(oMatch[1]);
				strRest = strRest.replace(oMatch[0],"").trim();
				oMatch = rgxDeepest.exec(strRest);
			}
		}
		// argument and most deeply nested to left
		return lstArgFns;
	}

	function fnComposed(lstFns) {
		// derive a nested function from a flat function list
		// rightmost function in list is innermost in nest
		return function(result) {
			for (var i = lstFns.length; i--;) {
				result = lstFns[i].call(this, result);
			}
			return result;
		};
	}

	function getValues(lstNodes, strAttrib) {
		return lstNodes.map(function (x) {
			return getAttrib(x, strAttrib);
		});
	}

	//return a string value for a @key(value) tag
	//or for @text, @line, first enclosing @heading/@project
	//@parent (text of), @level (integer string for nesting depth)
	//@index (1-based position among siblings)
	function getAttrib(oNode, strAttrib) {

		if (typeof(oNode) !== "object") return oNode.toString();

		var varNode = oNode, dctSource, lstChiln, lstNotes=[],
			lstEnvelope = ["heading", "project", "root"],
			strValue = "", strType, lngFileStart,
			lngLevel = 0, iStartChar;

		switch (strAttrib) {
		//default to @text, if no attrib is specified
		case undefined:
		case "":
		case "text":
			strValue = oNode.text();
			break;
		case "line":
			strValue = oNode.line();
			break;
		case "heading":
			strType = varNode.type();
			while (lstEnvelope.indexOf(strType) == -1) {
				varNode = varNode.parent;
				strType = varNode.type();
			}
			if (strType !== "root") strValue = varNode.text();
			break;
		case "parent":
			strValue = oNode.parent.text();
			break;
		case "level":
			while (varNode.parent) {
				lngLevel++;
				varNode = varNode.parent;
			}
			strValue = lngLevel.toString();
			break;
		case "index":
			strValue = (varNode.indexToSelf(true)+1).toString();
			break;
		case "note":
			if (varNode.hasChildren()) {
				lstChiln = varNode.children();
				lstChiln.forEach(function (oChild) {
					if (oChild.type() === "body") {
						lstNotes.push("\t\t" + oChild.text());
					}
				});
				if (lstNotes.length > 0) strValue="\n"+lstNotes.join("\n");
			}
			break;
		case "location":
			if (lngSourceFiles > 1) {
				strValue = iStartChar -
					sourceAtPosn(varNode.lineTextStart())["start"];
			} else {
				strValue = varNode.lineTextStart();
			}
			break;
		case "url":
			strValue = sourceAtPosn(varNode.lineTextStart())["url"] +
				"?line=" + lineNumInSource(varNode).toString();
			break;
		case "tags":
			strValue = tagsToString(varNode);
			break;
		case "file":
			strValue = sourceAtPosn(varNode.lineTextStart())["name"];
			break;
		case "linenum":
			strValue = lineNumInSource(varNode);
			break;
		default:
			if (oNode.hasTag(strAttrib)) strValue = oNode.tag(strAttrib);
		}
		return strValue;
	}

	function tagsToString (oNode) {
		var dctTags = oNode.tags(), strTag='', varVal, lstTags=[];
		Object.keys(dctTags).forEach(function (varKey) {
			strTag = "@"+varKey;
			varVal=dctTags[varKey];
			if (varVal) strTag += "(" + varVal + ")";
			lstTags.push(strTag);
		});
		return lstTags.join(" ");
	}

	function lineNumInSource(oNode) {
		var strValue;
		if (lngSourceFiles > 1) {
			strValue = oNode.lineNumber() -
				sourceAtPosn(oNode.lineTextStart())["line"];
		} else {
			strValue = oNode.lineNumber();
		}
		return strValue;
	}

	function sourceAtPosn(iChar) {
		// lstFileStarts//(sorted start positions [chars] in concat files)
		// lngSourceFiles//lstFilesStarts.length, cached for repeated use
		// dctSources={}; //(keyed by start position, {name: url: line: start:}
		var iStartPosn;
		if (lngSourceFiles >1) {
			for (var i = lngSourceFiles; i--;) {
				iStartPosn = lstFileStarts[i];
				if (iStartPosn <= iChar) {
					return dctSources[iStartPosn.toString()];
				}
			}
			return dctSources["0"];
		} else {
			return dctSources["0"];
		}
	}

	function expandFns(strLines, dctNames) {
		var rgxFnArgs = /fn:(\w*)\(([^\)]*)\)/,
			rgxIsPath = /^[\/\()]/,
			oMatch=null, lstParts, lstSubParts, lstNodes, lstValues,
			strFn="", strArg="", strAttrib, strPart,
			strFull = strLines, strMatch, fn,
			strFnResult="", strFor, varArg="",
			lstFnNames, lstFns, lngParts, lngSubParts;

		oMatch = rgxFnArgs.exec(strFull);
		while (oMatch) {
			strMatch = oMatch[0];
			lstFnNames = fnNestingList(strMatch);
			strArg = lstFnNames.shift();
			lstFns = [];
			for (var i = lstFnNames.length; i--;) {
				lstFns.push(dctViewFn[lstFnNames[i]]);
			}
			fn = fnComposed(lstFns);

			if (strArg !== undefined && (strArg.charAt(0) == DOLLAR)) {
				lstParts = strArg.split("@");
				if (lstParts.length > 1) {
					//derive a list of property values to
					//pass to the function
					lstNodes = dctNames[lstParts[0]];
					if (typeof lstNodes == "string") {
						if (lstNodes.indexOf(DOLLAR) !== -1) {
							lstNodes = expandDollars(lstNodes, dctNames);
						}
						if (rgxIsPath.exec(lstNodes)) {
							lstNodes = tree.evaluateNodePath(lstNodes);
						}
					}
					if (lstNodes.length) {
						strAttrib = lstParts[1];
						varArg = getValues(lstNodes, strAttrib);
					} else {
						varArg = [];
					}
				} else {
					varArg = dctNames[strArg];
					if (varArg && varArg.indexOf(DOLLAR) !== -1) {
						varArg = expandDollars(varArg, dctNames);
					}
					if (rgxIsPath.exec(varArg)) {
						varArg = tree.evaluateNodePath(varArg);
					}
				}
			} else {
				if (strArg) {
					varArg=[]; // split on commas except between quotes
					lstParts=strArg.trim().split(/\s*\'\s*/);
					lngParts = lstParts.length;
					for (i=0; i<lngParts; i+=1) {
						if (i % 2) {
							strPart=lstParts[i];
							if (strPart) varArg.push(strPart);
						} else {
							lstSubParts=lstParts[i].split(/\s*,\s*/);
							lngSubParts=lstSubParts.length;
							for (var j=0; j < lngSubParts; j+=1) {
								strPart= lstSubParts[j];
								if (strPart) varArg.push(strPart);
							}
						}
					}
				} else varArg = [];
			}

			if (typeof(fn) !== "function") {
				strFull = strFull.replace(
					strMatch, strMatch +"=UNKNOWN FUNCTION", "g");
			} else {
				strFnResult = fn(varArg, dctNames);
				strFull = strFull.replace(strMatch, strFnResult, "g");
			}
			oMatch = rgxFnArgs.exec(strFull);
		}
		return strFull;
	}

	//Can be a string expansion,
	//or getting a reference to an object,
	//and returning one of its attributes as a string.
	function expandDollars(varItem, dctNames) {
		var rgxLabel = /(\{(\$[^\}]*)\})/,
			rgxNodeAttribute = /^(\$.*)\@(.*)/,
			strNode, varNode, oNode, lstNodes, strAttrib="",
			oMatch = rgxLabel.exec(varItem),
			oAttribMatch = null,
			strLine = varItem.toString(), lstTrans=[],
			strMatch, strLabel, varValue, lngNodes, i,
			varResult, strType;

			//first expand the string before any @
			//then branch on the kind of object which the key returns
			//if there was no @ we should be getting a string
			//if (there is a @) {we try to return an attribute}

			while (oMatch !== null) {
				strMatch = oMatch[1];
				strLabel = oMatch[2];
				strAttrib="";

				oAttribMatch = rgxNodeAttribute.exec(strLabel);
				if (oAttribMatch !== null) {

					strNode = oAttribMatch[1];
					varNode= dctNames[strNode];
					if (varNode !== undefined) {
						strAttrib=oAttribMatch[2];
						if (strAttrib.charAt(0) == DOLLAR) {
							strAttrib = dctNames[strAttrib];
						}
						strLine = strLine.replace(strMatch, getAttrib(
							varNode, strAttrib), "gi");
					} else {
						strLine = strLine.replace(strMatch,
							strLabel + "=UNDEFINED LABEL", "gi");
					}

				} else {
					varValue = dctNames[strLabel];
					if (varValue !== undefined) {
						strType = typeof varValue;

						if (strType !== "string") {
							if (strType !== "function") {
								//assume a node - get an attribute
								strLine = strLine.replace(strMatch, getAttrib(
									varValue, strAttrib), "gi");
							} else {
								//a function apply to current element
								//and insert result with replace
								varNode = dctNames[dctNames.for[0]];
								varResult = varValue(varNode);
								strLine = strLine.replace(
									strMatch, varResult, "gi");
							}

						} else {
							//a string. Use simple search and replace
							strLine = strLine.replace(
								strMatch, varValue, "gi");
						}

						strLine = strLine.replace(
							strMatch, getAttrib(varValue, strAttrib), "gi");

					} else {
						strLine = strLine.replace(strMatch,
							strLabel + "=UNDEFINED LABEL");
					}
				}
				oMatch = rgxLabel.exec(strLine);
			}

			return strLine;
	}

	this.customMenu=function (strJSON) {
		dctCustomSettings = JSON.parse(strJSON);
		var lstMenu =  Object.keys(dctCustomSettings.menu);
		return lstMenu.sort();
	};

	this.defaultsJSON=function (_) {
		return JSON.stringify(dctDefaultSettings, null, "\t");
	};

	this.versionNumber=function () {
		return strVersionNumber;
	};

	function buildView(dctView, strKey) {
		var dctFLWOR, varTitle,
			strView = "";

		if (dctView !== undefined) {
			varTitle = dctView.title;
			if (varTitle) {
				strView += (varTitle + "\n\n");
			} else {
				strView += (strKey + "\n\n");
			}
			dctFLWOR = viewTree(dctView, {});
			strView += treeString(dctFLWOR);
		}
		return strView;
	}

	// Choose an item from a sorted query menu by (1-based) number
	// or by key
	function viewByKeyOrIndex(dctMenu, strViewName) {
		var dctView = dctMenu[strViewName],
			lstKeys, iIndex;
		if (!dctView) {
			iIndex = parseInt(strViewName, 10);
			if (iIndex) {
				lstKeys = Object.keys(dctMenu);
				if (iIndex <= lstKeys.length) {
					dctView=dctMenu[lstKeys.sort()[iIndex-1]];
				}
			}
		}
		return dctView;
	}

	function htmlComment(dctView, strViewName, dctSourceSpec) {
		// <!-- OPTIONAL HTML-COMMENTED FRONT MATTER FOR REPORT
		// Name of query, datestamp, source spec and
		// matching sources found and queried, FLWOR details of query
		var oTime = new Date(),
			lstComment = ["<!-- TXTQUERY [Rob Trew 2014](https://github.com/RobTrew/txtquery-tools) -->",
				"<!-- ",
				"PLATFORM: Built on Hogbay Software's [FoldingText](http://www.foldingtext.com) platform",
				"REPORT TEMPLATE: '" + strViewName + "'",
				"DATESTAMP: " + oTime.toISOString(),
				"SETTINGS APPLIED (command line overrides any FLWOR and ViewMenu.json defaults)", specString(dctSourceSpec),
					"\t(Note: mtime filter = 'only files last modified within N[smhdw] range')",
				"TAGGED (key@value TP/FT) TEXT FILES  QUERIED:"], dctFile;
		for (var key in dctSources) {
			dctFile=dctSources[key];
			lstComment.push("\t[" + dctFile.name + "](" + dctFile.url + ")");
		}
		lstComment.push("FLWOR QUERY:");
		lstComment.push(JSON.stringify(dctView, null, "\t"));
		lstComment.push("-->");
		lstComment.push("<!-- REPORT OUTPUT BEGINS -->\n");
		return lstComment.join('\n');
	}

	function specString(dctSpec) {
		if (dctSpec) {
			return JSON.stringify(dctSpec, null, "\t");
		} else {
			return "";
		}
	}

	this.customJSONByName = function(_, strViewName, strJSON) {
		var dctView, strViewJSON, dctMenu;
		if (strJSON) dctCustomSettings = JSON.parse(strJSON);

		dctMenu=dctCustomSettings.menu || dctCustomSettings;
		dctView = viewByKeyOrIndex(dctMenu, strViewName);
		if (dctView !== undefined) {
			strViewJSON = JSON.stringify(dctView, null, "\t");
		} else {
			strViewJSON = strViewName + " not found ...";
		}
		return strViewJSON;
	};

	this.customViewByName=function(_, dctOptions, dctFLWOR) {
		//options.viewname, options.packlist,
		//options.frontmatter, options.sourcespec
		var strViewName=dctOptions.viewname, lstFileSet=dctOptions.packlist,
			blnInfo=dctOptions.frontmatter,
			dctView, dctMenu, strReport,
			strHTMLComment='', strHTMLCloseTag='';

		if (lstFileSet !== undefined) lstPackList=lstFileSet;

		// get a view from a settings file or a simple FLWOR file
		if (dctFLWOR) {
			dctView=dctFLWOR;
		} else {
			dctMenu=dctCustomSettings['menu'];
			if (dctMenu) dctView=viewByKeyOrIndex(dctMenu, strViewName);
		}

		if (dctView) {
			prepareSourceList();
			if (blnInfo) {
				strHTMLComment =
					htmlComment(dctView, strViewName,
						dctOptions['sourcespec']);
				strHTMLCloseTag = "<!-- REPORT OUTPUT ENDS -->";
			}
			strReport = buildView(dctView, strViewName);
			return strHTMLComment + strReport + strHTMLCloseTag;
		} else {
			return strViewName + " not found ...";
		}
	};
}

/// END OF TextQuery

function SmallTime() {
		// preprocess a nodePath to translate curly-bracketed date phrases to ISO
	this.translatePathDates = function (strPath) {
		var strDblQuote = String.fromCharCode(34);
		return strPath.replace(
			/{[^}]+}/g, strDblQuote +
				datePhraseToISO(strPath) + strDblQuote);
	};

	this.readDatePhrase = function(strPhrase, iWeekStart) {
		return phraseToDate(strPhrase, iWeekStart);
	};

		// informal phrases like "now +7d", "thu", jan 12 2pm" to ISO string
	// yyyy-mm-dd [HH:MM] (unless 00:00)
	// returns strPhrase itself if can not be parsed
	function datePhraseToISO(strPhrase, iWeekStart) {
		if (typeof iWeekStart === "undefined" || iWeekStart === null) {
			iWeekStart = 1; //Monday=1 (or Sunday=0)
		}
		var dte = phraseToDate(strPhrase, iWeekStart);
		if (dte) {
			if (isNaN(dte)) {
				return strPhrase;
			} else {
				return fmtTP(dte);
			}
		} else {
			return strPhrase;
		}
	}

	// Javascript Date() to ISO date string
	function fmtTP(dte) {
		if (dte) {
			var strDate = [dte.getFullYear(),
					("0" + (dte.getMonth()+1)).slice(-2),
					("0"+ dte.getDate()).slice(-2)].join("-"),
				strTime = [("00"+dte.getHours()).slice(-2),
					("00"+dte.getMinutes()).slice(-2)].join(":");
			if (strTime !== "00:00") {
				return [strDate, strTime].join(" ");
			} else {
				return strDate;
			}
		} else {
			return "";
		}
	}

	// preprocess a nodePath to translate curly-bracketed date phrases to ISO
	this.translatePathDates = function (strPath) {
		var strDblQuote = String.fromCharCode(34);
		return strPath.replace(
			/{[^}]+}/g, strDblQuote +
				datePhraseToISO(strPath) + strDblQuote);
	};

	// if a time specified for today has already passed, assume tomorrow
	function adjustDay(dteAnchor) {
		if (dteAnchor < new Date()) {
			if (dteAnchor > (new Date().setHours(0,0,0,0))) {
				dteAnchor.setDate(dteAnchor.getDate() +1);
			}
		}
	}

	// informal phrases like "now +7d", "thu", jan 12 2pm" to .js Date()
	function phraseToDate(strPhrase, iWeekStart) {
		if (typeof iWeekStart === "undefined" || iWeekStart === null) {
			iWeekStart = 1; //Monday
		}

		var DAY_MSECS = 86400000, WEEK_MSECS = 604800000,
			lstAnchors = ["now", "toda","tomo", "yest",
				"yesterday", "today", "tomorrow"],
			lstDate = ["y", "w", "d", "year", "yr", "week",
				"wk","day", "month", "o"],
			lstTime = ["h", "hr", "hour", "m", "min", "minute"],
			lstAmPm = ["am", "pm", "a", "p"], lstSign = ["+", "-"],
			dctMonths = {"jan":0, "feb":1, "mar":2, "apr":3, "may":4, "jun":5,
				"jul":6, "aug":7, "sep":8, "oct":9, "nov":10, "dec":11},
			dctShift = {"next":1, "last":-1, "ago":0},
			dctNum = {"zero":0, "one":1, "two":2, "three":3, "four":4,
				"five":5, "six":6, "seven":7, "eight":8, "nine":9, "ten":10,
				"eleven":11, "twelve":12, "thirteen":13, "fourteen":14,
				"fifteen":15, "sixteen":16, "seventeen":17, "eighteen":18,
				"nineteen":19, "twenty":20, "thirty":30, "forty":40,
				"fifty":50, "sixty":60, "seventy":70, "eighty": 80,
				"ninety":90},
			dctOrd = {"first":1, "second":2, "third":3, "fifth":5,
				"eighth":8, "twelfth":12},
			lstNth = ["st","nd","rd","th"],
			dctAnchor = extractISODate(strPhrase),
			dteAnchor = dctAnchor["date"],
			lstTokens, //= tokens(dctAnchor['rest']),
			lngTokens, // = lstTokens.length,
			rDelta = 0, dteResult = null,
			lstTokens = tokens(dctAnchor["rest"]),
			lngTokens = lstTokens.length, blnOrd = false,
			strBase = "", strAffix = "",
			strTkn = "", strLower = "", iToday, iWkDay, iDay,
			lngSign =+1, rQuant = 0, strUnit="d", i,
			blnDate = false, blnNewQuant = false, strAbbrev ="",
			blnNewUnit = false, blnPostColon = false, blnNextLast = false;

		// Closure - shares core variables with parent function phraseToDate
		function upDate(strUnit) {
			var lngYear, strMonth="", iMonth=-1,
				dteToday=null, dteNow=null, rYearDelta=0;
			rQuant *= lngSign;
			switch (strUnit) {
			case "w":
				if (blnNextLast) {
					iToday = (iToday || new Date().getDay());
					rDelta += (((7 - (iToday * lngSign))+(iWeekStart * lngSign)) * (DAY_MSECS * lngSign));
				} else {
					rDelta += (rQuant * WEEK_MSECS);
				} break;
			case "d":
				if (blnOrd) {
					if (rQuant < dteAnchor.getDate()) {
						dteAnchor.setMonth(dteAnchor.getMonth() + 1);
					}
					dteAnchor.setDate(rQuant);
				} else {
					rDelta += (rQuant * DAY_MSECS);
				} break;
			case "h": // add quantity of hours
				if (!blnDate) {dteAnchor = new Date(); blnDate = true;}
				rDelta += (rQuant * 3600000); break;
			case "H": // set the clock hour
				dteAnchor.setHours(~~rQuant);
				adjustDay(dteAnchor); break;
			case "m": // add quantity of minutes
				if (!blnDate) {dteAnchor = new Date(); blnDate = true;}
				rDelta += (rQuant * 60000); break;
			case "M": // set the clock minutes
				dteAnchor.setMinutes(~~rQuant);
				adjustDay(dteAnchor); break;
			case "o": // month(s)
				if ((rYearDelta = ~~(rQuant / 12)) !== 0) {
					dteAnchor.setFullYear(dteAnchor.getFullYear()+rYearDelta);
				}
				dteAnchor.setMonth(dteAnchor.getMonth() + (~~rQuant) % 12);
				if (blnNextLast) {dteAnchor.setDate(1);}
				break;
			case "y":
			case "Y":
				if (rQuant > 31) { // just 2019 vs jul 17
					dteAnchor.setFullYear(~~rQuant);
				} else {
					dteAnchor.setFullYear(dteAnchor.getFullYear() + ~~rQuant);
				} break;
			case "a":
				if (!blnPostColon) {
					dteAnchor.setHours(~~rQuant);
					adjustDay(dteAnchor);
				}
				break;
			case "p":
				if (blnPostColon) {
					if (dteAnchor.getHours() < 12) {
						dteAnchor.setHours(dteAnchor.getHours() + 12);
						adjustDay(dteAnchor);
					}
				} else  {
					if (rQuant < 12) {
						dteAnchor.setHours(~~rQuant + 12);
					} else {
						dteAnchor.setHours(~~rQuant);
					}
					adjustDay(dteAnchor);
				} break;
			default:
				if (strUnit.length >= 3) {
					if (strUnit in dctMonths) {
						dteAnchor.setMonth(dctMonths[strUnit]);
						if (rQuant <= 31) {
							if (rQuant) {
								dteAnchor.setDate(rQuant);
							} else {
								dteAnchor.setDate(1);
							}
						} else {
							dteAnchor.setFullYear(rQuant);
							dteAnchor.setDate(1);
						}
						dteToday = new Date(); dteToday.setHours(0,0,0,0);
						if (dteAnchor < dteToday) {
							dteAnchor.setFullYear(
								dteAnchor.getFullYear()+1);
						}
					}
				}
			}
			blnNewUnit = blnNewQuant = false; blnNextLast = false; rQuant = 0;
			blnDate = true; lngSign = 1; //scope of sign limited to one number
		}

		function extractWeekPhrase(strDate) {
			var match = /(mon|tue|wed|thu|fri|sat|sun)\w*\s+(la|last|th|this|ne|nxt|next)\s+we*k/i.exec(strDate),
				dte=null, strRest=strDate;

			if (match !== null) {
				var dteThen, strRel, lngStartDate, iMatch;
				dteThen= new Date();
				iToday = dteThen.getDay();
				lngStartDate=dteThen.getDate()-(iToday-iWeekStart);
				dteThen.setHours(0,0,0,0);
				dteThen.setDate(lngStartDate+(weekDay(match[1])-iWeekStart));
				strRel=match[2].charAt(0);
				if (strRel !== 't') {
					if (strRel !== 'l') dte=new Date(dteThen.valueOf() + WEEK_MSECS);
					else dte=new Date(dteThen.valueOf() - WEEK_MSECS);
				} else dte=dteThen;

				iMatch = match.index;
				strRest = strDate.substring(0, iMatch) +
					strDate.substring(iMatch+match[0].length);
			}
			return {'date':dte, 'rest':strRest.trim()};
		}

		/////////////
		// START OF phraseToDate MAIN code: ISO date ?
		/////////////
		dctAnchor = extractISODate(strPhrase);
		dteAnchor = dctAnchor['date'];
		// if not, WeekdayName+(last|this|this)+'week' ?
		if (!dteAnchor) dctAnchor = extractWeekPhrase(strPhrase);
		dteAnchor = dctAnchor['date'];
		lstTokens = tokens(dctAnchor['rest']);
		lngTokens = lstTokens.length;

		if (lngTokens) { // get a base date,
			if (dteAnchor) {
				blnDate = true;
			} else {
				dteAnchor = new Date();
			}
			dteAnchor.setHours(0,0,0,0);
		}
		for (i=0; i<lngTokens; i++) { // tokens adjust the Anchor date or Delta
			strTkn = lstTokens[i]; strBase = strAffix = "";
			if (strTkn) {
				blnOrd = false; strAffix = "";
				strLower = strTkn.toLowerCase();
				if (strLower.length > 1) {
					strAffix = strLower.slice(-2);
					if (strAffix === "th") {strBase = strLower.slice(0,-2);}
				}

				// normalise any numeric
				if (strLower in dctNum) {
					strLower = dctNum[strLower].toString();
				} else if (strLower in dctOrd) {
					strLower = dctOrd[strLower].toString();
					blnOrd = true;
				} else if (strBase && strBase in dctNum) {
					strLower = dctNum[strBase].toString();
					blnOrd = true;
				}

				if (strLower.slice(-1) === "s") {
					strLower = strLower.slice(0,-1);
				}
				strAbbrev = strLower.slice(0,4);
				if (!isNaN(strLower)) {
					rQuant += parseFloat(strLower);
					blnNewQuant = true;
					if (rQuant > 2000 && rQuant < 2500) {
						if (blnNewUnit) {
							upDate(strUnit);
						} else {
							strUnit = "y"; blnNewUnit = true;
						}
					}
				} else if (lstNth.indexOf(strLower) !== -1) {
					blnOrd = true;
				} else if (lstDate.indexOf(strLower) !== -1) {
					if (strLower !== "month") {
						strUnit = strTkn[0];
					} else {
						strUnit = "o";
					}
					blnDate = blnNewUnit = true;
				} else if (strLower.substring(0,3) in dctMonths) {
					strUnit = strLower.substring(0,3);
					blnDate = blnNewUnit = true;
				} else if (lstTime.indexOf(strLower) !== -1) {
					strUnit = strTkn[0];
					blnNewUnit = true;
				} else if (lstAnchors.indexOf(strAbbrev) !== -1) {
					blnDate = true;
					if (strAbbrev !== "now") {
						if (strAbbrev !== "toda") {
							strUnit = "d"; rQuant = 1;
							blnNewUnit = blnNewQuant = true;
							if (strAbbrev !== "tomo") {
								lngSign = -1;
							}
						}
					} else {
						dteAnchor = new Date();
					}
				} else if ((iWkDay = weekDay(strLower)) !== -1) {
					iToday = (iToday || new Date().getDay());
					strUnit = "d";
					blnNewUnit = blnNewQuant = true;
					if (iWkDay > iToday) {
						rQuant = iWkDay - iToday;
					} else {
						rQuant = 7 - (iToday - iWkDay);
					}
					if (blnNextLast && (iToday !== iWkDay)) {
						rQuant += 7 * lngSign; lngSign=1;
					}
				} else if (lstSign.indexOf(strTkn) !== -1) {
					if (strTkn == "+") {
						lngSign = 1;
					} else {
						lngSign = -1;
					}
				} else if (strTkn == ":" || strTkn == ".") {
					blnPostColon = true; upDate("H"); strUnit = "M";
					rQuant = 0;
					blnNewQuant = false; blnNewUnit = true;
				} else if (strLower in dctShift) {
					if (dctShift[strLower]) { // unles "ago"
						blnNextLast = blnNewQuant = true; rQuant = 1;
						if (strTkn !== "next") {lngSign = -1;}
					} else if (rDelta > 0) { // "ago: reflect around now"
						rDelta = -rDelta;
						dteAnchor = new Date();
						if (strUnit !== "h") {dteAnchor.setHours(0,0,0,0);}
					}
				} else if (lstAmPm.indexOf(strLower) !== -1) {
					strUnit = strTkn[0];
					blnNewUnit = blnNewQuant = true;
				}
				if (blnNewUnit && blnNewQuant) {
					upDate(strUnit);
				}
			} else {strLower = "";}
		}
		// No more tokens. Default unit and quantity is 1 day
		if (blnNewUnit && !blnNewQuant) {
			rQuant = 1; upDate(strUnit);
		} else if (!blnNewUnit && blnNewQuant) {
			upDate("d");
		}
		if (blnDate) {
			dteResult = new Date(dteAnchor.valueOf() + rDelta);
		} else {
			dteResult = dteAnchor;
		}
		return dteResult;
	}

	// separate any token which looks like yyyy-mm-dd from the rest
	function extractISODate(strDate) {
		var match = /((\d{4})-(\d{2})-(\d{2}))/.exec(strDate),
			dte = null, strRest = strDate;

		if (match !== null) {
			var lngYear, lngMonth, lngDay, iMatch;
			lngYear = parseInt(match[2],10);
			lngMonth = parseInt(match[3],10) -1; //zero based
			lngDay = parseInt(match[4],10);
			dte = new Date(lngYear, lngMonth, lngDay);
			iMatch = match.index;
			strRest = strDate.substring(0, iMatch) + " " +
				strDate.substring(iMatch+10);
		}
		return {"date":dte, "rest":strRest.trim()};
	}

	// English weekday name to JS index into the week
	function weekDay(strTkn) {
		var lstDays = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"],
			lstFullDays = ["sunday", "monday", "tuesday", "wednesday",
			"thursday", "friday", "saturday"],
			iDay = lstDays.indexOf(strTkn.slice(0,3));
		if (iDay !== -1) {
			if (lstFullDays[iDay].slice(0,strTkn.length) !== strTkn) {
				return -1; //month != monday
			}
		}
		return iDay;
	}

	// informal date phrase to array of tokens
	function tokens(strWords) {
		var lstWords = strWords.split(/\s*\b\s*/),
			rgxNum = /^\d+/, match,
			lngWords = lstWords.length, strWord, strNum,
			lstTokens = [], i, strRest="";
		for (i=0; i<lngWords; i++) {
			strWord = lstWords[i].trim();
			if (strWord) {
				match = rgxNum.exec(strWord);
				if (match !== null) {
					strNum = match[0]; lstTokens.push(strNum);
					strRest = strWord.substring(strNum.length);
					if (strRest) {lstTokens.push(strRest);}
				} else {
					lstTokens.push(strWord);
				}
			}
		}
		return lstTokens;
	}
}

/// End of SmallTime

	// Create a report
	var	oReport,
		options,
		varCmd,
		dctFLWOR;

	try{
		options=JSON.parse(param);
	}catch(e){
		//error in the JSON - eccentric filename character ?
		return [e, "JSON Parse error. A text file with an eccentric name ?"];
	}

	varCmd=options.cmd;

	if (tree) tree.ensureClassified();
	oReport = new TextQuery(tree);

	// and call functions (with any arguments) specified in
	// options.cmd, options.argv

	if (varCmd) {
		//return options.packlist;

		switch (varCmd) {
		case "defaultsJSON":
			return oReport.defaultsJSON(null);
		case "customViewByName":
			// Two passes: json string nested in json object
			dctFLWOR=JSON.parse(JSON.stringify(options.viewjson));
			return oReport.customViewByName(null, options, dctFLWOR);
		case "version":
			return oReport.versionNumber();
		default:
			return "Command not recognised: " + varCmd;
		}
	} else {
		return "Expected JSON string as parameter {cmd:commandName, args:[]}";
	}
}


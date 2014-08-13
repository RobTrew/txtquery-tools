property pTitle : "Make random tagged and nested tasks"property pDescription : "for testing new plain text queries with txtQuery.sh"property pVer : "0.03"property pAuthor : "Rob Trew"property pblnDebug : false-- Generates a new foldingtext document populated with a random set of tagged and nested tasks-- define subset of tags to use by setting true|false in the following record-- NB if you create any additional tags, you will need to define value lists or functions-- for them in dctTagVals below either as:-- 1. An array of possible values e.g. ['alpha', 'beta', 'gamma'] from which a random choice will be made-- 2. A lambda (anonymous function) which returns a value e.g. function() {return (randomInt(1,19)*5).toString();}-- 3. The string 'day' for which a random date will be generated-- 4. The string 'time' for which a random date and time will be generated-- SET THE RANGE OF DATES WITHIN WHICH RANDOM DATE TAGS WILL BE GENERATEDproperty pNow : (current date)property pFrom : pNow - 30 * daysproperty pTo : pNow + 60 * daysproperty precRange : {earliest:pFrom, latest:pTo}property precTags : {activetags:{priority:true, start:true, due:true, mins:true, alert:true, next:true, done:true}}property pUnixEpoch : missing valueproperty pstrJS : "
function(editor, options) {
		var tree=editor.tree(), oParent=tree.root,
			lstSyntax = ['process','affected','instrument','circumstance','time'],
			dctTags = options.activetags,
		lstTagSet = Object.keys(dctTags),
		lstActiveTags=lstTagSet.filter(
			function (oTag) {return dctTags[oTag];}),
		lngActiveTags=lstActiveTags.length,
		iLastTag=lngActiveTags-1,
		dctLex={
			'process':['build','make', 'think', 'work', 'drink','give','call', 'try', 'winnow', 'aggregate', 'link', 'derive', 'summarise'],
			'affected':['school','system','program','question','water','book','earth','umbrella','time','thing','world','life','footsoldier','company','problem', 'group', 'number','weaver','toothbrush','derivation','method', 'mountain', 'termite mound'],
			'instrument':['school','system','program','question','water','book','earth','umbrella','time','thing','world','life','footsoldier','company','problem', 'group', 'number','weaver','sandwich', 'theorem', 'hypothesis', 'assumption', 'contradiction', 'function', 'derivation'],
			'circumstance':['at the office', 'in the library', 'at home', 'in the forest', 'on the mountain', 'while commuting', 'at lunch', 'after breakfast', 'before supper', 'tomorrow morning', 'in a boat', 'on the sea', 'by a bridge', 'along the river', 'under the maples', 'with lambda', 'with lemma'],
			'time':['early','on Fridays', 'next week', 'in two days', 'at the end of the month', 'before 2015', 'after 2017','after the harvest','during the spring sowing','after Michaelmas','in Trinity', 'tomorrow', 'this evening', 'at 7pm on Monday', 'by August', 'first thing', 'before retiring']
		},
		
		dteStart=new Date(),
		dteHorizon=new Date(),

		dctTagVals={
			'priority':[1, 2, 3],
			'start':'day',
			'alert':'time',
			'due':'time',
			'done':'time',
			'mins':function() {return (randomInt(1,19)*5).toString();}
		},

		lngCount, lngPhrase=60, strPhrase='', lstParts=[], lstPhrases=[],lngSyntax=lstSyntax.length,blnTag,
		lstWords, lngWords, strKey, iWord, strWord;

		function randomInt(min, max) {
			return Math.floor(Math.random() * (max - min + 1)) + min;
		}

		function simplePhrase(lngLevel, dteLocalStart, dteLocalDue) {
			var strPrefix, strPhrase, lngPhrase,
				dteFrom=dteLocalStart, dteTo=dteLocalDue, varTagVal,
				strType, varValue, strValue, lngRange,
				lstParts = [], lstSeen=[], iTag, dteMoment, lngTags;


			// CREATE A RANDOM PHRASE
			// using only a number of words that matches the nesting level,
			lngPhrase=Math.min(lngSyntax, lngLevel);
			for (var j=0;j<lngPhrase;j++) {

				// get a paradigmatic set of lexemes for the nth position in lstSyntax
				strKey=lstSyntax[j];
				lstWords=dctLex[strKey];
				lngWords = lstWords.length;
				iWord=randomInt(0,lstWords.length-1);
				strWord=lstWords[iWord];
				lstParts.push(strWord);
			}

			// AND ADD A SUBSET OF THE ACTIVE TAGS, WITH RANDOM VALUES
			// How many active tags do we have ? lngActiveTags

			// How many tags shall we use ?
			lngTags = randomInt(0,lngActiveTags-1);
			if (lngTags < 0) lngTags = 0;

			// Which one shall we use next ?

			for (j=lngTags; j--;) {
				// choose a tag we haven't used
				iTag=randomInt(0, iLastTag);
				while (lstSeen.indexOf(iTag) !== -1) {
					iTag=randomInt(0, iLastTag);
				}
				lstSeen.push(iTag);
				// get the key
				strKey = lstActiveTags[iTag];


				varTagVal=dctTagVals[strKey];
				if (varTagVal) {
					// generate a value
					if (varTagVal instanceof Array) {
						lngRange=varTagVal.length;
						varValue = varTagVal[randomInt(0, lngRange-1)];
					} else {
						switch (typeof varTagVal) {
							case 'string':
								if (varTagVal=='time') {
									dteMoment = randomDate(dteFrom, dteTo, true);
									varValue = fmtTP(dteMoment);
								} else if (varTagVal=='day') {
									dteMoment = randomDate(dteFrom, dteTo, false);
									varValue = fmtTP(dteMoment);
								} else {
									varValue = varTagVal + '??';
								}
								break;
							case 'function':
								varValue = varTagVal();
								break;
							default:
								varValue = '';
						}
						if (strKey=='@start') dteFrom=dteMoment;
						else if (strKey=='@due') dteTo=dteMoment;
					}
					// and append the @key(value) to the phrase
					lstParts.push(
						['@',strKey,'(',varValue.toString(),')'].join(''));
				} else {
					// @next etc (no value)
					lstParts.push('@' + strKey);
				}
			}


			if (lngLevel < 3) {
				strPrefix = (Array(lngLevel+1).join('#')) + ' ';
			} else {
				strPrefix = '- ';
			}

			strPhrase = strPrefix + lstParts.join(' ').trim();
			return {'phrase':strPhrase, 'begins':dteFrom, 'ends':dteTo};
		}

		function fmtTP(dte) {
			if (dte) {
				var strDate = [dte.getFullYear(),
						('0' + (dte.getMonth()+1)).slice(-2),
						('0'+ dte.getDate()).slice(-2)].join('-'),
					strTime = [('00'+dte.getHours()).slice(-2),
						('00'+dte.getMinutes()).slice(-2)].join(':');
				if (strTime !== '00:00') {
					return [strDate, strTime].join(' ');
				} else {
					return strDate;
				}
			} else {
				return '';
			}
		}

		function randomDate(start, end, blnTime) {
			var lngDelta = Math.floor((Math.random() * (
					end.getTime()- start.getTime()))),
			dteRandom = new Date(start.getTime() + lngDelta);
			if (blnTime) {
				dteRandom.setMinutes(randomInt(0,2) * 30);
			} else {
				dteRandom.setHours(0);
				dteRandom.setMinutes(0);
			}
			return dteRandom;
		}

		function phraseTree(tree, oParent, lngDepth, lngWidth, lngLevel, dteEarliest, dteLatest) {
			var oNode, lngLessDepth=lngDepth-1, dct, strPhrase;
			if (lngDepth) {
				for (var i=lngWidth;i--;) {
					dct = simplePhrase(lngLevel, dteEarliest, dteLatest);
					strPhrase = dct['phrase'];

					// Add a blank line before any Level 1 heading
					if (strPhrase.charAt(0) == '#') {
						oParent.appendChild(tree.createNode());
					}
					oNode=tree.createNode(strPhrase);
					oParent.appendChild(oNode);
					if (lngLessDepth) {
						phraseTree(tree, oNode, lngLessDepth, lngWidth, lngLevel+1, dct['begins'], dct['ends']);
					}
				}
			}
		}

		dteStart.setTime(options.earliest);
		dteHorizon.setTime(options.latest);

		tree.beginUpdates();
		phraseTree(tree, oParent, 4,3, 1, dteStart, dteHorizon);
		tree.endUpdates();

		tree.ensureClassified();
		return tree.toString();
}

"on run	set varResult to missing value		set dteFrom to earliest of precRange	set dteTo to latest of precRange	set recRange to {earliest:AsDate2JS(dteFrom), latest:AsDate2JS(dteTo)}		set recOptions to recRange & precTags	tell application "FoldingText"		if not pblnDebug then			set oDoc to make new document			--do shell script "sleep 0.5"			tell oDoc				set varResult to (evaluate script pstrJS with options recOptions)				activate			end tell		else			-- debug script automatically refers to the SDK version of the editor			-- which must be open: FoldingText > Help > SDK > Run Editor			set varResult to (debug script pstrJS with options recOptions)		end if	end tell	return varResultend runon AsDate2JS(dteAs)	if pUnixEpoch is missing value then set pUnixEpoch to UnixEpoch()	return (dteAs - pUnixEpoch) * 1000end AsDate2JSon UnixEpoch()	tell (current date)		set {its year, its day, its time} to {1970, 1, 0}		set its month to 1 -- set after day for fear of Feb :-)		return (it + (my (time to GMT)))	end tellend UnixEpoch
// The FORTH Checker module. Monday, December 19, 2022

const checkOrder = ( arr, defwords ) => {
    const dictionary = ["shell", "i", "loop", "do", "again", "until", "while", "begin", "else", "then", "if", ";", "alloc", "interpreting", "word", "branch", "1branch", "0branch", "cont", "jmpcont", "lit", "leave", "bye", "stdin@", "stdin!", "xt>name", "xt>clientdata!", "xt>clientdata@", "xt>data", "dis", "see", "execute", "'", "unloop", "literal", "]", "[", ",@", ",", "does>", "create", ":", "cr", ".", "accept", "string=", "type", "words", "over", "rot", "swap", "dup", "drop", "hello", "C@", "@", "C!", "!", "variable", "constant", "hex", "octal", "decimal", "not", "xor", "or", "and", "<=", ">=", "<", ">", "<=0", ">=0", "<0", ">0", "0<>", "0=", "*/", "*", "%", "/", "-", "+", "R!", "R@", "R>", ">R", "sp_pushr", "rp_pushs", "rp_clean", "pstack"];

    // Simple syntax check for proper ordering of source words in an incrementally growing dictionary
    let res=[], current_dictionary=dictionary;
    for( i in arr ){
	if( !current_dictionary.includes( arr[i].value ) ){
	    let j = defwords.map( o => o.word ).indexOf(arr[i-1].value);
	    console.error( arr[i].value + ', ' + arr[i-1].value + ', ' + j );
	    if( ':' == arr[i-1].value || (j>= 0 && defwords[j].scope > 0)  )
		current_dictionary.push( arr[i].value );
	    else
		res.push( arr[i] );
	}
    }
    return res;
};

const gotoImplementation = ( text, fragment )=> {
    const dictionary = ["shell", "i", "loop", "do", "again", "until", "while", "begin", "else", "then", "if", ";", "alloc", "interpreting", "word", "branch", "1branch", "0branch", "cont", "jmpcont", "lit", "leave", "bye", "stdin@", "stdin!", "xt>name", "xt>clientdata!", "xt>clientdata@", "xt>data", "dis", "see", "execute", "'", "unloop", "literal", "]", "[", ",@", ",", "does>", "create", ":", "cr", ".", "accept", "string=", "type", "words", "over", "rot", "swap", "dup", "drop", "hello", "C@", "@", "C!", "!", "variable", "constant", "hex", "octal", "decimal", "not", "xor", "or", "and", "<=", ">=", "<", ">", "<=0", ">=0", "<0", ">0", "0<>", "0=", "*/", "*", "%", "/", "-", "+", "R!", "R@", "R>", ">R", "sp_pushr", "rp_pushs", "rp_clean", "pstack"];
    const regex = new RegExp(`([=%><@\\+\\-\\*\\/\\'\\[\\]\\;\\:\\,\\!\\w]+)[ \\n\\r]+(${fragment})[ \\n\\r]+`, 'gi');
    const results = [];
    // Test first for a number
    if( !isNaN( fragment ) ){
	results.push({
	    value: fragment,
	    index: -1,
	    prefix: null
	});
    }
    else{
	// Test for a FORTH primitive
	if( dictionary.includes( fragment ) ){
	    results.push({
		value: fragment,
		index: -1,
		prefix: null
	    });
	}
	else{
	    regex.lastIndex = 0;
	    let defwords = getDefiningWords(text);
	    while ((matches = regex.exec(text)) && results.length < 100) {
		let j = defwords.map( o => o.word ).indexOf( matches[1] );
		if( ':' == matches[1] || (j>= 0 && defwords[j].scope > 0) )
		    results.push({
			value: matches[0],
			index: matches.index,
			prefix:matches[1]
		    });
	    }
	}
    }
    return results;
};

const getOrderedWords = (text) => {
    const filterComments = (arr) => {
	let word, res = [], skipping = false;
	for( i in arr ){
	    word = arr[i].value;
	    if( word.startsWith('(') ) skipping=true;
	    if( !skipping ) res.push( arr[i] );
	    if( word.startsWith(')') ) skipping=false;
	}
	return res;
    };
    const filterConstStr = (arr) => {
	let word, res = [], skipping = false;
	for( i in arr ){
	    word = arr[i].value;
	    if( word.startsWith('"') ) skipping=true;
	    if( !skipping ) res.push( arr[i] );
	    if( word.endsWith('"') ) skipping=false;
	}
	return res;
    };
    const filterConstNaNs = (arr) => {
	let word, res = [];
	for( i in arr ){
	    word = arr[i].value;
	    if( isNaN(word) ) res.push( arr[i] );
	}
	return res;
    };
    

    const regex = new RegExp("\\( |\\)[ \\n\\r]|[=%><@\"\\+\\-\\*\\/\\'\\[\\]\\;\\:\\,\\!\\w]+", 'gi');
    let words = [];
    regex.lastIndex = 0;
    while ((matches = regex.exec(text)) && words.length < 500) {
	words.push({
	    value: matches[0],
	    index: matches.index,
	});
    }
    return filterConstNaNs( filterConstStr( filterComments(words) ) );
};

const getDefiningWords = (text) => {
    let defwords = [
	{ word: 'variable',	scope: 1 },
	{ word: 'constant',	scope: 1 }
    ];
    let filtered = getOrderedWords( text );
    let i = 1, state=0, rec=null, j=-1;
    while( i<filtered.length ){

	// console.log( "> " + i + "\t" +
	// 	     filtered[i-1].value + ", " + filtered[i].value + ", "
	// 	     + state );

	if( ':' == filtered[i-1].value ){
	    state = 1;
	    rec = { word: filtered[i].value, scope: 0 };
	}
	j = defwords.map( elt => elt.word ).indexOf( filtered[i-1].value );
	// console.log( i + '\t' + j + '\t' + filtered[i].value ); if( j>0 ) console.log(defwords[j]);
	if( 0 <= j && 0 < defwords[j].scope ){
	    defwords.push({ word: filtered[i].value, scope: defwords[j].scope - 1 });
	    i += 1;
	}
	if( 'create' == filtered[i].value ){
	    if( 1 == state ) rec.scope += 1;
	}
	if( ';' == filtered[i].value ){
	    state = 0;
	    if( rec.scope > 0 ) defwords.push( rec );
	}
	i+=1;
    }
    return defwords;
};

const getUndefinedWords = (text) => {
    let defwords = getDefiningWords( text );
    let filtered = getOrderedWords( text );
    return checkOrder( filtered, defwords );
};

// // Make sure we got a filename on the command line.
// if (process.argv.length < 3) {
//   console.log('Usage: node ' + process.argv[1] + ' FILENAME [fragment]');
//   process.exit(1);
// }

// // Read the file and print its contents.
// var fs = require('fs'),
//     filename = process.argv[2],
//     fragment = process.argv[3];

// fs.readFile(filename, 'utf8', function(err, data) {
//     if (err) throw err;
//     console.log('OK: ' + filename + ', ' + fragment);

//     var res = getOrderedWords(data);
//     // console.log( res.length, res );

//     res = getDefiningWords(data);
//     console.log( res.length, res );
//     // if( undefined != fragment ){
//     // 	var impl = gotoImplementation(data, fragment);
//     // 	console.log( impl.length, impl );
//     // }
// });

exports.getUndefinedWords	= getUndefinedWords;
exports.gotoImplementation	= gotoImplementation;
exports.getDefiningWords	= getDefiningWords;

const gotoImplementation = ( text, fragment )=> {
    const dictionary = ["shell", "i", "loop", "do", "again", "until", "while", "begin", "else", "then", "if", ";", "alloc", "interpreting", "word", "branch", "1branch", "0branch", "cont", "jmpcont", "lit", "leave", "bye", "stdin@", "stdin!", "xt>name", "xt>clientdata!", "xt>clientdata@", "xt>data", "dis", "see", "execute", "'", "unloop", "literal", "]", "[", ",@", ",", "does>", "create", ":", "cr", ".", "accept", "string=", "type", "words", "over", "rot", "swap", "dup", "drop", "hello", "C@", "@", "C!", "!", "variable", "constant", "hex", "octal", "decimal", "not", "xor", "or", "and", "<=", ">=", "<", ">", "<=0", ">=0", "<0", ">0", "0<>", "0=", "*/", "*", "%", "/", "-", "+", "R!", "R@", "R>", ">R", "sp_pushr", "rp_pushs", "rp_clean", "pstack"];
    const regex = new RegExp(`:[ \\n\\r]+(${fragment})[ \\n\\r]+`, 'gi');
    const results = [];

    if( !isNaN( fragment ) ){
	results.push({
	    value: fragment,
	    index: -1
	});
    }
    else{
	if( dictionary.includes( fragment ) ){
	    results.push({
		value: fragment,
		index: -1
	    });
	}
	else{
	    regex.lastIndex = 0;
	    while ((matches = regex.exec(text)) && results.length < 100) {
		results.push({
		    value: matches[0],
		    index: matches.index,
		});
	    }
	}
    }
    return results;
};

const getUndefinedWords = (text) => {
    const dictionary = ["shell", "i", "loop", "do", "again", "until", "while", "begin", "else", "then", "if", ";", "alloc", "interpreting", "word", "branch", "1branch", "0branch", "cont", "jmpcont", "lit", "leave", "bye", "stdin@", "stdin!", "xt>name", "xt>clientdata!", "xt>clientdata@", "xt>data", "dis", "see", "execute", "'", "unloop", "literal", "]", "[", ",@", ",", "does>", "create", ":", "cr", ".", "accept", "string=", "type", "words", "over", "rot", "swap", "dup", "drop", "hello", "C@", "@", "C!", "!", "variable", "constant", "hex", "octal", "decimal", "not", "xor", "or", "and", "<=", ">=", "<", ">", "<=0", ">=0", "<0", ">0", "0<>", "0=", "*/", "*", "%", "/", "-", "+", "R!", "R@", "R>", ">R", "sp_pushr", "rp_pushs", "rp_clean", "pstack"];

    
/*
    const raw = text
    // Split on blanks
	  .split(/[ \n\r]+/g)
    // Remove blank lines
	  .filter((p) => p.trim());

    let results = filterConstNaNs( filterConstStrings( filterComments( raw ) ) );
*/
    
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
    let words = [], filtered;
    regex.lastIndex = 0;
    while ((matches = regex.exec(text)) && words.length < 100) {
	words.push({
	    value: matches[0],
	    index: matches.index,
	});
    }
    filtered = filterConstNaNs( filterConstStr( filterComments(words) ) );

    const checkOrder = ( arr ) => {
	// Simple syntax check for proper ordering of source words in an incrementally growing dictionary
	let res=[], current_dictionary=dictionary;
	for( i in arr ){
	    if( !current_dictionary.includes( arr[i].value ) ){
		if( ':' != arr[i-1].value )
		    res.push( arr[i] );
		else
		    current_dictionary.push( arr[i].value );
	    }
	}
	return res;
    };

    // return filtered.filter( x => !dictionary.includes( x.value ) );
    return checkOrder( filtered );
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
//     var res = getUndefinedWords(data);
//     console.log( res.length, res );
//     if( undefined != fragment ){
// 	var impl = gotoImplementation(data, fragment);
// 	console.log( impl.length, impl );
//     }
// });

exports.getUndefinedWords = getUndefinedWords;
exports.gotoImplementation = gotoImplementation;

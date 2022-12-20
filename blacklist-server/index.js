// Tentative FORTH LSP-server Saturday, December 17, 2022
const FORTHChecker = require('./wip.js');

const {
  DiagnosticSeverity,
  TextDocuments,
  createConnection,
} = require('vscode-languageserver');

const {TextDocument} = require('vscode-languageserver-textdocument');

const getBlacklisted = (text) => {
    const blacklist = [
	'foo',
	'bar',
	'baz',
    ];
    
    const regex = new RegExp(`\\b(${blacklist.join('|')})\\b`, 'gi');
    
    const results = [];
    regex.lastIndex = 0;
    while ((matches = regex.exec(text)) && results.length < 100) {
	results.push({
	    value: matches[0],
	    index: matches.index,
	});
    }
    return results;
};

const blacklistToDiagnostic = (textDocument) => ({ index, value }) => ({
  severity: DiagnosticSeverity.Warning,
  range: {
    start: textDocument.positionAt(index),
    end: textDocument.positionAt(index + value.length),
  },
  message: `${value} is not in dictionary at this point.`,
  source: 'FORTH Checker',
});

const getDiagnostics = (textDocument) =>
  FORTHChecker.getUndefinedWords(textDocument.getText())
      .map(blacklistToDiagnostic(textDocument));

const connection	= createConnection();
const documents		= new TextDocuments(TextDocument);

connection.onInitialize(() => ({
    capabilities: {
	textDocumentSync: documents.syncKind,
	implementationProvider: true
    },
}));

documents.onDidChangeContent(change => {
    connection.sendDiagnostics({
	uri: change.document.uri,
	diagnostics: getDiagnostics(change.document),
    });
});

connection.onImplementation( params => {
    const symbolAtPoint = ( data ) => {
	let txt = document.getText(), impl;
	let i   = 0, found=false, p;
	// Search point position in text array
	while( i<txt.length && !found ){
	    p = document.positionAt(i);
	    if( data.position.line == p.line && data.position.character == p.character ){
		found = true;
	    }
	    else i = i+1;
	}
	if( found ){
	    // Search forward
	    let j = i, k = i;
	    while( j<txt.length && txt[j] != ' ' && txt[j] != '\n' && txt[j] != '\r' ) j += 1;
	    while( k>=0 && txt[k] != ' ' && txt[k] != '\n' && txt[k] != '\r' ) k -= 1;
	    impl = { fragment: txt.slice( k+1, j ), start:k+1, end:j };
	}
	else
	    impl = { fragment: null, start:-1, end:-1 };
	
	return impl;
    };

    const toLocation = ({ index, value, prefix }) => ({
	    uri: params.textDocument.uri,
	    range: (index >= 0) ? {
		start	: document.positionAt(index),
		end	: document.positionAt(index + value.length)
	    } : {
		start	: document.positionAt(impl.start),
		end	: document.positionAt(impl.end)
	    }
    });
    
    let document	= documents.get(params.textDocument.uri);
    let impl		= symbolAtPoint(params);
    if( impl.fragment ){
	let results	= FORTHChecker.gotoImplementation( document.getText(), impl.fragment );
	// for( let i in results ){ console.error( results[i].index + ', ' + results[i].value + ', ' + results[i].prefix ); }
	let res         = results.map( toLocation );
	// for( let i in res ){ console.error( res[i].range  ); }
	return res;
	
	// if( result.index >= 0 ){
	//     // Definition/Implementation found
	//     return({
	// 	uri: params.textDocument.uri,
	// 	range: {
	// 	    start	: document.positionAt(result.index),
	// 	    end		: document.positionAt(result.index + result.value.length)
	// 	}
	//     });
	// }
	// else{
	//     // Could be a FORTH primitive
	//     return ({
	// 	uri: params.textDocument.uri,
	// 	range: {
	// 	    start	: document.positionAt(impl.start),
	// 	    end		: document.positionAt(impl.end)
	// 	}
	//     });
	// }

    }
    else return( undefined );
});

documents.listen(connection);
connection.listen();

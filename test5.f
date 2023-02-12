( -*- mode: forth;  -*- )
: ENUMERANT 1 alloc create [ ' lit ] literal , , does> dup @ 1 + dup rot ! create [ ' lit ] literal , , does> ;

( Facts or signs are variables which are either known or not )
( When evaluated in unknwon state facts prompt for their values )
( When evaluated in known state facts as variables return their values )
( The address of the status is embedded in the code for the fact word as lit value )
( The address is 0 when unknown otherwise is the string pointer to the value retuned by asking )
: ASK " What is the value (string) of " stringcat type cr accept ;
( A fact is either known and the word returns its string value, or not and the word asks for and stores the answer )
: FACT 1 alloc create [ ' lit ] literal , , [ ' lit ] literal , , does> dup @ if @ swap drop else swap xt>name ASK dup rot rot swap ! then ;
( Status fact returns 0 if unknown or the string pointer to the value if known )
( Done by reverse engineering the first instruction LIT x in the code segment of the word )
: STATUS ' xt>data 8 + @ @ ;

"t" constant TRUE "nil" constant NIL
FACT A FACT B FACT C

: ISTRUE TRUE string= ;
: ISNIL NIL string= ;

: RULE001 A ISTRUE logand B ISNIL logand C ISTRUE logand 1 ;



( -*- mode: forth;  -*- )
: ENUMERANT 1 alloc create [ ' lit ] literal , , does> dup @ 1 + dup rot ! create [ ' lit ] literal , , does> ;

: ASK "What is the value? (string)" type cr accept ;
( A fact is either known and the word returns its string value, or not and the word asks for and store the value )
: FACT 1 alloc create [ ' lit ] literal , , does> dup @ if @ else ASK dup rot rot swap ! then ;

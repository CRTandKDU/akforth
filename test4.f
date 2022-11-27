( -*- mode: forth;  -*- )
( Base unit is mm )
: inches 254 10 */ ;
: feet [ 254 12 * ] literal 10 */ ;
: yards [ 254 36 * ] literal 10 */ ;
: centimeters 10 * ;
: meters 1000 * ;

( Defining CONS(TANT) in Forth: 100 CONST hundred )
: CONST create [ ' lit ] literal , , [ ' leave ] literal , ;

( Defining thunks in Forth: 1 ADDER INC )
: ADDER create [ ' lit ] literal , , does> + ;

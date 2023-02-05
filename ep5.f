( -*- mode: forth;  -*- )
( x n -- x^n )
: power 1 swap 1 swap do over * loop swap drop ;
( x -- n largest n such that x^n less than top )
20 constant TOP
: exponent 1 begin 1 + over over power TOP <= while 1 - swap drop ;
: evenly-divisible 0 19 17 13 11 7 5 3 2 1 begin swap dup 0= if drop leave else dup exponent power * then again ;

( n -- Square of sum of integers minus sum of squares )
: ep6 dup dup dup 1 - * swap 1 + * 3 / swap 3 * 2 + * 4 / ;

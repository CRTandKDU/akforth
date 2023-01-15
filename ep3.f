( -*- mode: forth;  -*- )
( Highest prime of 600851475143 in base 65536 )
( Use 139 58761 60103 hiprime )
( Square Root by Newton Method -- there are subtelties with integer division )
: isqrtn dup 2 / over over / over + 2 / begin rot over over over / + 2 / >R rot drop swap R> over over > while drop swap drop ;
0 variable CALLS
65536 constant BASE
: 4dup 1 4 do 3 nover loop ;
: 4drop 1 4 do drop loop ;
: uplimit 4dup drop rot 0= if swap dup BASE 2 / < if BASE * + isqrtn else then else drop drop BASE 2 / 1 - then ;
( x2 x1 x0 p -- q2 q1 q0 r )
: idiv 0 1 3 do BASE * swap >R >R rot R> + R> over over dup >R % >R / R> R> swap loop ;
( x2 x1 x0 -- q2 q1 q0 p )
: hiprime 3 begin CALLS @ 1 + CALLS ! 4dup idiv 0= if 4 noverdrop else 4drop 2 + then uplimit over > while CALLS @ . " iterations." type ;   

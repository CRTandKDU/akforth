( -*- mode: forth;  -*- )
( <upto> -- fizzbuzzsum )
: ep1 0 1 rot do i 3 % 0= if i + else i 5 % 0= if i + then then loop ;

: ep2 0 0 1 begin dup rot + dup 2 % 0= if rot over + rot rot then dup 4000000 >= until ;

( <N> -- <integer_sqrt_N> )
( Linear search using addition )
: isqrt 0 >R 3 >R 1 >R begin R> R> R> 1 + >R dup 2 + >R + dup >R swap dup rot >= while drop R> drop R> drop R> ;
( Binary Search -- problematic for large numbers )
: isqrt2 dup 1 + 0 begin over over + 2 / dup >R dup * >R rot dup R> > if rot rot drop R> else rot drop R> rot then over over 1 + - 0<> while ;
( Newton Method -- there are subtelties with integer division )
: isqrtn dup 2 / over over / over + 2 / begin rot over over over / + 2 / >R rot drop swap R> over over > while drop swap drop ;

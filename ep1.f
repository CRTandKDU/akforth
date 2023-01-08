( -*- mode: forth;  -*- )
( <upto> -- fizzbuzzsum )
: ep1 0 1 rot do i 3 % 0= if i + else i 5 % 0= if i + then then loop ;

: ep2 0 0 1 begin dup rot + dup 2 % 0= if rot over + rot rot then dup 4000000 >= until ;

( <N> -- <integer_sqrt_N> )
( Linear search using addition )
: isqrt 0 >R 3 >R 1 >R begin R> R> R> 1 + >R dup 2 + >R + dup >R swap dup rot >= while drop R> drop R> drop R> ;
( Binary Search )
: isqrtbin dup 1 + 0 >R >R begin  dup R> R> dup >R swap dup >R  + 2 / dup dup * rot  <= if R> R> rot >R swap >R  else R> R> dup  >R swap drop  swap >R  then drop R> R> dup >R swap dup >R 1 - - 0<>  while drop R> R> drop ;

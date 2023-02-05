( -*- mode: forth;  -*- )
( Find the largest palindrome made from the product of two 3-digit numbers )
: palindrome >R >R - 0= if R> - 0= if R> - 0= else drop R> drop 0 then else drop drop R> R> drop drop 0 then ;
: split 1 5 do dup 10 % swap 10 / loop ;
: row do dup i * dup 100000 < if drop else split palindrome if i unloop leave then then loop 0 ;
: highest -999 -100 do i -999 -100 row dup <0 if over over * unloop leave then drop drop loop 0 ;


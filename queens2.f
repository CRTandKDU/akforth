
0 variable S1 0 variable S2 0 variable ARRAY
0 variable CALLS

: 2dup S1 ! S2 ! S2 @ S1 @ S2 @ S1 @ ;
: 3dup S1 ! S2 ! ARRAY ! ARRAY @ S2 @ S1 @ ARRAY @ S2 @ S1 @ ;
: 2in3dup S1 ! S2 ! ARRAY ! ARRAY @ S2 @ ARRAY @ S2 @ S1 @ ;
: min 2dup > if swap then drop ;

: arr2d 2dup * 2 + alloc swap over ! swap over 4 + ! ;
: arr2d! S1 ! rot swap over 4 + @ * rot + 4 * 8 + + S1 @ swap ! ;

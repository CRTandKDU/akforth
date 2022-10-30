( -*- mode: forth;  -*- )

0 variable CALLS

: 2dup dup >R swap dup >R swap R> R> ;
: 3dup dup >R rot dup >R rot dup >R rot R> R> R> rot swap ;
: 2in3dup >R 2dup R> ;
: min 2dup > if swap then drop ;

( <cols> <rows> arr2d -- <array> )
: arr2d 2dup * 2 + alloc swap over ! swap over 4 + ! ;
: arr2d-to rot swap over 4 + @ * rot + 4 * 8 + + ;
( <array> <col> <row> <value> arr2d! -- )
: arr2d! >R arr2d-to R> swap ! ;
( <array> <col> <row> arr2d@ -- <value> )
: arr2d@ arr2d-to @ ;

8 constant SIZE
SIZE SIZE arr2d constant B


: board 0 SIZE 1 - do i 0 SIZE 1 - do i 2in3dup swap arr2d@ 0= if ". " else "Q " then type loop cr drop loop drop ;
: check-row 0 swap do i 2in3dup swap arr2d@ 0<> if drop drop 0 unloop leave then loop drop drop 1 ;
: check-up-diag swap 2dup min 0 swap do 1 - swap 1 - swap 3dup arr2d@ 0<> if drop drop drop 0 unloop leave then loop drop drop drop 1 ;
: check-down-diag swap 2dup SIZE 1 - swap - min 0 swap do 1 + swap 1 - swap 3dup arr2d@ 0<> if drop drop drop 0 unloop leave then loop drop drop drop 1 ;
: no-checks 3dup check-row if 3dup check-up-diag if 3dup check-down-diag else 0 then else 0 then ;

: solve CALLS @ 1 + CALLS !
  dup SIZE 1 - > if 1
                else 0 SIZE 1 -
		do i swap no-checks 
		if 3dup swap 8 arr2d! 3dup 1 + swap drop solve if 1 unloop leave
		else 3dup swap 0 arr2d! then
		then swap drop
		loop drop drop 0 
		then ;




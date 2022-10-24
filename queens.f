8 constant SIZE
SIZE SIZE arr2d constant B
0 variable S1 0 variable S2 0 variable ARRAY
0 variable CALLS

: 2dup S1 ! S2 ! S2 @ S1 @ S2 @ S1 @ ;
: 3dup S1 ! S2 ! ARRAY ! ARRAY @ S2 @ S1 @ ARRAY @ S2 @ S1 @ ;
: 2in3dup S1 ! S2 ! ARRAY ! ARRAY @ S2 @ ARRAY @ S2 @ S1 @ ;
: min 2dup > if swap then drop ;

: board 0 SIZE 1 - do i 0 SIZE 1 - do i 2in3dup swap arr2d@ . loop cr drop loop drop ;
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




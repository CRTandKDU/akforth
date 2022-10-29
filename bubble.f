( -*- mode: forth;  -*- )
: bubble
  dup if >R
	 over over < if swap then
	 R> swap >R 1 - bubble R>
      else
	drop
      then ;

: sort 1 - dup 0 swap do >R R@ bubble R> loop drop ;

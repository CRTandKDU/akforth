( -*- mode: forth;  -*- )
( Find the 10001st prime )
( A bizarre solution based on Deleglise Rivat algorithm to count primes less than x )
( External implementation in C++ by Kim Walisch https://github.com/kimwalisch )
( Known fact: the 10000th prime is 104729. )
: ep7 104729 begin 2 + dup i2string "C:\Users\jmchauvet\Documents\primecount-master\Release\primecount.exe " stringcat system 10001 - 0= until ;

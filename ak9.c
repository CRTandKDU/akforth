/* Experiments in FORTH implementations with a view to the Z80
 * Source: Andreas Klimas [[https://w3group.de/forth_course.html]]
 * See also: `lbforth.c' in same directory for alternative ideas.
 *
 * File: ak9.c
 * By: jmc
 * Date: Sunday, October 23, 2022
 *
 * Extensions: nxm arrays
 */

// Hints:
// M-: (require 'imenu-list)
// M-x imenu-list-minor-mode

#include <stdio.h>

static short RUNNING	= 1;
static short errno	= 0;

// Some functions are reimplemented (simplistically) to break some dependencies
// ---------------------------------------------------------------------------------

/* Array-based Storage Allocator */
#ifndef MEM_STACK_SIZE
#define MEM_STACK_SIZE 8192
#endif

static size_t   store_base[MEM_STACK_SIZE];
static size_t	*store_end	= store_base+MEM_STACK_SIZE;
static size_t	*store		= store_base;

/* #ifndef STR_POOL_SIZE */
/* #define STR_POOL_SIZE 1024 */
/* #endif */

/* static char     scratch[STR_POOL_SIZE]; */
/* static char     *pad = scratch; */

void *MALLOC( unsigned long long len ){
  size_t *ret = store;
  if( store + (size_t)len < store_end ){
    store += (size_t)len;
    return (void *)ret;
  }
  return (void *)0;
}

void *CALLOC( unsigned long long num, unsigned long long len ){
  size_t *ret = store;
  if( store + (size_t)(num*len) < store_end ){
    store += (size_t)(num*len);
    return (void *)ret;
  }
  return (void *)0;
}

/* Classes of ANSI characters */
#define UC(c)	((int)c)
int  isupper(int c) { return ( c >= UC('A') && c <= UC('Z') ) ? 1 : 0; }
int  isalpha(int c){ return ((c >= UC('a') && c <= UC('z')) || (c >= UC('A') && c <= UC('Z')) ? 1 : 0); }
int  isdigit(int c){ return (c >= UC('0') && c <= UC('9') ? 1 : 0); }
int  isspace(int c){
  return (c == '\t' || c == '\n' ||
	  c == '\v' || c == '\f' || c == '\r' || c == ' ' ? 1 : 0); }

/* String functions */
/* Source: $OpenBSD: strtol.c,v 1.7 2005/08/08 08:05:37 espie Exp $ */
#define ERANGE          34      /* Math result not representable */
#define LONG_MIN        -2147483647
#define LONG_MAX        2147483647

long STRTOL(const char *nptr, char **endptr, int base){
  const char *s;
  long acc, cutoff;
  int c;
  int neg, any, cutlim;
  /*
   * Skip white space and pick up leading +/- sign if any.
   * If base is 0, allow 0x for hex and 0 for octal, else
   * assume decimal; if base is already 16, allow 0x.
   */
  s = nptr;
  do {
    c = (unsigned char) *s++;
  } while (isspace(c));
  if (c == '-') {
    neg = 1;
    c = *s++;
  } else {
    neg = 0;
    if (c == '+')
      c = *s++;
  }
  if ((base == 0 || base == 16) &&
      c == '0' && (*s == 'x' || *s == 'X')) {
    c = s[1];
    s += 2;
    base = 16;
  }
  if (base == 0)
    base = c == '0' ? 8 : 10;
  /*
   * Compute the cutoff value between legal numbers and illegal
   * numbers.  That is the largest legal value, divided by the
   * base.  An input number that is greater than this value, if
   * followed by a legal input character, is too big.  One that
   * is equal to this value may be valid or not; the limit
   * between valid and invalid numbers is then based on the last
   * digit.  For instance, if the range for longs is
   * [-2147483648..2147483647] and the input base is 10,
   * cutoff will be set to 214748364 and cutlim to either
   * 7 (neg==0) or 8 (neg==1), meaning that if we have accumulated
   * a value > 214748364, or equal but the next digit is > 7 (or 8),
   * the number is too big, and we will return a range error.
   *
   * Set any if any `digits' consumed; make it negative to indicate
   * overflow.
   */
  cutoff = neg ? LONG_MIN : LONG_MAX;
  cutlim = cutoff % base;
  cutoff /= base;
  if (neg) {
    if (cutlim > 0) {
      cutlim -= base;
      cutoff += 1;
    }
    cutlim = -cutlim;
  }
  for (acc = 0, any = 0;; c = (unsigned char) *s++) {
    if (isdigit(c))
      c -= '0';
    else if (isalpha(c))
      c -= isupper(c) ? 'A' - 10 : 'a' - 10;
    else
      break;
    if (c >= base)
      break;
    if (any < 0)
      continue;
    if (neg) {
      if (acc < cutoff || (acc == cutoff && c > cutlim)) {
	any = -1;
	acc = LONG_MIN;
	errno = ERANGE;
      } else {
	any = 1;
	acc *= base;
	acc -= c;
      }
    } else {
      if (acc > cutoff || (acc == cutoff && c > cutlim)) {
	any = -1;
	acc = LONG_MAX;
	errno = ERANGE;
      } else {
	any = 1;
	acc *= base;
	acc += c;
      }
    }
  }
  if (endptr != 0)
    *endptr = (char *) (any ? s - 1 : nptr);
  return (acc);
}

char * STRDUP (const char *s){
  size_t len ; //  = strlen (s) + 1;
  int i = 0;
  while( s[i] != '\0' ) ++i; len = (size_t)(i+1);
  
  char *new = (char *)MALLOC (len);
  if (new == NULL)
    return NULL;
  for( i=0; i<=len; i++ ) new[i] = s[i];
  return new;
}

int STRCMP (const char *p1, const char *p2){
  const unsigned char *s1 = (const unsigned char *) p1;
  const unsigned char *s2 = (const unsigned char *) p2;
  unsigned char c1, c2;
  do
    {
      c1 = (unsigned char) *s1++;
      c2 = (unsigned char) *s2++;
      if (c1 == '\0')
        return c1 - c2;
    }
  while (c1 == c2);
  return c1 - c2;
}

FILE * S_stdin = NULL;

/* Begin FORTH implementation */
// ---------------------------------------------------------------------------------
typedef unsigned long long cell_t;
typedef struct xt_t { // Execution Token
  struct xt_t *next;
  char *name;
  void (*prim)(void);
  struct xt_t **data; // address into high level code
  short has_lit; // does consume the next ip as literal (0branch, 1branch, lit)
  short immediate;
  short hidden;
} xt_t;

// DICTIONARY
// ---------------------------------------------------------------------------------
static xt_t *dictionary; 
static xt_t *current_xt; // current xt
static xt_t *latest; // last defined word

// DATA or PARAMETER STACK
// ---------------------------------------------------------------------------------
#ifndef DATA_STACK_SIZE
#define DATA_STACK_SIZE 32
#endif
static cell_t sp_base[DATA_STACK_SIZE], *sp_end=sp_base+DATA_STACK_SIZE;
static cell_t *sp=sp_base-1;

// CALL RETURN STACK
// ---------------------------------------------------------------------------------
/* static xt_t *macros;  // course03 */
static xt_t **definitions=&dictionary;	// where to store new words
static xt_t **ip;			// course03, instruction pointer

#ifndef RETURN_STACK_SIZE
#define RETURN_STACK_SIZE 32
#endif
static xt_t **rp_base[RETURN_STACK_SIZE], ***rp_end=rp_base+RETURN_STACK_SIZE;
static xt_t ***rp=rp_base-1;

static xt_t *current_xt; // current xt
static xt_t *xt_dup,
  *xt_swap,
  *xt_drop,
  *xt_interpreting,
  *xt_word,
  *xt_hello,
  *xt_sstdin,
  *xt_gstdin,
  *xt_bye,
  *xt_lit,
  *xt_sup,
  *xt_leave,
  *xt_branch,
  *xt_0branch,
  *xt_1branch,
  *xt_i,
  *xt_rppushs,
  *xt_sppushr,
  *xt_rpclean;

static int is_compile_mode; // course03: we are either interpreting or compiling
#ifndef CODE_SIZE
#define CODE_SIZE 16384
#endif
static xt_t *code_base[CODE_SIZE], **code=code_base, **code_end=code_base+CODE_SIZE;


static xt_t *compile(xt_t *xt) ;
static void interpreting(char *w) ;

static void pstack(void){
  cell_t *i;
  xt_t ***j;
  printf("\tSP STACK> "); for( i=sp_base;i<=sp;i++) printf("%d ", *i); printf("\n");
  printf("\tRP STACK> "); for( j=rp_base;j<=rp;j++) printf("%d ", *j); printf("\n");
}  

// UTILITIES and PARSING INPUT
// ---------------------------------------------------------------------------------
static xt_t *find(xt_t *dict, char *w) { // find word either in dictionary or macros
  for(;dict;dict=dict->next) if(!STRCMP(dict->name, w)) return dict;
  return 0; // not found
}

static void ok(void) { // print data stack, then ok>
  cell_t *i;
  printf( "\n\033[36mSTORE: [%6d / %6d]\n\033[0m", store - store_base, store_end - store_base );
  printf( "\033[36mSTACK: [%6d / %6d]\n\033[0m", sp - sp_base, sp_end - sp_base );
  printf( "\033[36mRETST: [%6d / %6d]\n\033[0m", rp - rp_base, rp_end - rp_base );
  printf( "\033[36mCODES: [%6d / %6d]\n\033[0m", code - code_base, code_end - code_base );
  for(i=sp_base;i<=sp;i++) printf("%d ", *i);
  printf("ok> ");
  /* if(*sp) printf( "%d", *sp ); */
}

static int next_char(FILE * stream) {
  static int last_char;
  if(last_char=='\n') ok(); // ok> prompt
  last_char=fgetc(NULL == stream ? stdin : stream);
  return last_char==EOF?0:last_char;
}

static int skip_space_comments(FILE * stream) {
  int ch;
  while((ch=next_char(stream)) && isspace(ch));
  if( '(' == ch ){
    while( (ch = next_char(stream)) && (')' != ch) );
    while((ch=next_char(stream)) && isspace(ch));
  }
  return ch;
}

static char *word() { // symbol might have maximal 256 bytes
  static char buffer[256], *end=buffer+sizeof(buffer)-1;
  char *p=buffer, ch;
  if(!(ch=skip_space_comments(S_stdin))) return 0; // no more input

  *p++=ch;
  if(ch=='"') { // +course02: string handling
    while(p<end && (ch=next_char(S_stdin)) && ch!='"') *p++=ch;
  } else {
    while(p<end && (ch=next_char(S_stdin)) && !isspace(ch)) *p++=ch;
  }
  *p=0; // zero terminated string
  return buffer;
}

static void terminate(char *msg) {
  fprintf(stderr, "terminated: %s\n", msg);
  RUNNING = 0;
}

static char *to_pad(char *str) {		// add for course02: copy str into scratch pad
  // Saturday, September 24, 2022	changed logic to accumulative
  // Friday, September 30, 2022		changed again to use memory allocator
  /* char *old; */
  /* int i = 0, len; */
  /* while( str[i] != '\0' ) ++i; len = (size_t)i; // strlen */
  /* if( ((pad-scratch)+len) > (sizeof(scratch)-1) ){ */
  /*   terminate( "OM Error" ); */
  /* } */
  /* old = pad; */
  /* for( i=0; i<=len; i++ ) *pad++ = str[i];	// memcpy */
  /* *pad++ =0;					// zero byte at string end */
  /* return old; */
  return STRDUP( str );
}

// DICTIONARY OPERATIONS
// ---------------------------------------------------------------------------------
static xt_t *add_word(char *name, void (*prim)(void)) {
  xt_t *xt=CALLOC(1, sizeof(xt_t));
  if( NULL == xt ){
    terminate( "OM Error" );
  }
  else{
    xt->next		= *definitions;
    *definitions	= xt;
    xt->name		= STRDUP(name);
    xt->prim		= prim;
    xt->data		= code; // current high level code pointer, compilation target
    xt->has_lit		= 0;
    xt->immediate	= 0;
    xt->hidden          = 0;
  }
  return latest = xt;
}

// STACK and CALL RETURN STACK OPERATIONS
// ---------------------------------------------------------------------------------
static void sp_push(cell_t value) {
  if(sp==sp_end) terminate("SO Error"); // stack overflow
  *++sp=value;
}

static cell_t sp_pop(void) {
  if(sp<sp_base) terminate("SU Error"); // stack underflow
  return *sp--;
}

static void rp_push(xt_t **ip) {
  if(rp==rp_end) terminate("RO Error"); // return stack overflow
  *++rp=ip;
}
static xt_t **rp_pop(void) {
  if(rp<rp_base) terminate("RU Error"); // return stack underflow
  return *rp--;
}

// PRIMITIVES and BUILTINS
// --------------------------------------------------------------------------------
static void f_mul(void) { int v1=sp_pop(); *sp*=v1; }
static void f_add(void) { int v1=sp_pop(); *sp+=v1; }
static void f_sub(void) { int v1=sp_pop(); *sp-=v1; }
static void f_div(void) { int v1=sp_pop(); *sp/=v1; }
static void f_mod(void) { int v1=sp_pop(); *sp%=v1; }

static void f_zerop(void)  { int v1=sp_pop(); sp_push( (cell_t)( v1 == 0 ? 1 : 0 )); }
static void f_nzerop(void) { int v1=sp_pop(); sp_push( (cell_t)( v1 == 0 ? 0 : 1 )); }
static void f_pos(void)    { int v1=sp_pop(); sp_push( (cell_t)( v1 > 0 ? 1 : 0 )); }
static void f_neg(void)    { int v1=sp_pop(); sp_push( (cell_t)( v1 < 0 ? 1 : 0 )); }
static void f_poseq(void)  { int v1=sp_pop(); sp_push( (cell_t)( v1 >= 0 ? 1 : 0 )); }
static void f_negeq(void)  { int v1=sp_pop(); sp_push( (cell_t)( v1 <= 0 ? 1 : 0 )); }
static void f_sup(void)    { int v1=sp_pop(); int v2=sp_pop(); sp_push( (cell_t)( v2 > v1 ? 1 : 0 )); }
static void f_inf(void)    { int v1=sp_pop(); int v2=sp_pop(); sp_push( (cell_t)( v2 < v1 ? 1 : 0 )); }
static void f_supeq(void)  { int v1=sp_pop(); int v2=sp_pop(); sp_push( (cell_t)( v2 >= v1 ? 1 : 0 )); }
static void f_infeq(void)  { int v1=sp_pop(); int v2=sp_pop(); sp_push( (cell_t)( v2 <= v1 ? 1 : 0 )); }

static void f_hello_world(void) {
  printf("akFORTH\nok> ");
}

static void f_bye(void){ RUNNING = 0; }

static void f_drop(void) {sp_pop();} // drop top of stack

static void f_words(void) { // display all defined words
  xt_t *w;
  for(w=dictionary;w;w=w->next) if(!w->hidden) printf("%s ", w->name);
  printf("\n");
}

static void f_dot(void) {
  printf("%d ", sp_pop());
}

static void f_type(void){ // course02
  fputs((char*)sp_pop(), stdout);
}

static void f_stringeq(void){
  char *s1 = (char *)sp_pop();
  char *s2 = (char *)sp_pop();
  sp_push( STRCMP( s1, s2 ) ? (cell_t) 0 : (cell_t) 1 );
}

static void f_accept(void){
  // Due to I/O implementation `accept' has to be the last word on a line
  static char *acceptbuf[ 32 ];
  /* char *ignore; */
  /* ignore = gets( (char *)acceptbuf ); */
  scanf( "%s", acceptbuf );
  sp_push( (cell_t) STRDUP( (char *)acceptbuf ) );  
}

static void f_cr(void){ // course02, newline
  fputc('\n', stdout);
}

static void f_leave(void) { // course03, return from subroutine
  ip=rp_pop();
}

static void f_lit(void) {
  sp_push((cell_t)*ip++);
}

static xt_t *compile(xt_t *xt) {
  if(code>=code_end) terminate("CS Error"); // code segment full
  return *code++=xt;
}

static void literal(cell_t value) {
  compile(xt_lit);
  *code++=(xt_t*)value;
}

static void f_docol(void) { // course03, VM: enter function (word)new 
  rp_push(ip); // at runtime push current ip on return stack
  ip=current_xt->data; // and continue at the high level code
  /* data will be set in add_word() and represent the
     current dictionary pointer */
}

static void f_colon() { // course03, define a new word
  char *w=word(); // read next word which becomes the word name
  add_word(STRDUP(w), f_docol);
  is_compile_mode=1; // switch to compile mode
}

static void f_create(){
  char *w=word(); // read next word which becomes the word name
  add_word(STRDUP(w), f_docol);
}

static void f_comma(){
  xt_t *xt = (xt_t *) sp_pop();
  *code++ = xt;
}

static void f_semis(void) { // course03, macro, end of definition
  *code++=xt_leave; // compile return from subroutine
  is_compile_mode=0; // switch back to interpret mode
}

static void f_branch(void) { ip=(void*)*ip; } // unconditional jump

static void f_0branch(void) { // jump if top of stack is zero
  if(sp_pop()) ip++;
  else         ip=(void*)*ip;
}

static void f_1branch(void) { // jump if top of stack is zero
  if(sp_pop()) ip=(void*)*ip;
  else         ip++;
}

static void f_word(void) { sp_push((cell_t)word()); }

static void f_interpreting(void) { interpreting((void*)sp_pop()); }

static void f_dup(void){cell_t t=*sp; sp_push(t);}

static void f_swap(void) {
	cell_t t=*sp;
	*sp=sp[-1];
	sp[-1]=t;
}

static void f_over(void){
  sp_push( sp[-1] );
}

static void f_rot(void){
  cell_t a = sp_pop();
  cell_t b = sp_pop();
  cell_t c = sp_pop();
  sp_push( b );
  sp_push( a );
  sp_push( c );
}

static void f_and(void){
  cell_t a = sp_pop();
  cell_t b = sp_pop();
  sp_push( a & b );
}

static void f_or(void){
  cell_t a = sp_pop();
  cell_t b = sp_pop();
  sp_push( a | b );
}

static void f_xor(void){
  cell_t a = sp_pop();
  cell_t b = sp_pop();
  sp_push( a ^ b );
}

static void f_not(void){
  cell_t a = sp_pop();
  sp_push( ~a );
}

static void f_if(void) {	// macro, execute at compiletime
  *code++=xt_0branch;
  sp_push((cell_t)code++);	// push forward reference on stack
}

static void f_else(void) {	// macro, execute at compiletime
  xt_t ***dest=(void*)sp_pop(); // pop address (from f_if) 
  *code++=xt_branch;		// compile a jump
  sp_push((cell_t)code++); 
  *dest=code; 
}

static void f_then(void) {	// macro, execute at compiletime
  xt_t ***dest=(void*)sp_pop();
  *dest=code;			// resolve forward reference given by f_if or f_else
}

static void f_begin(void) {	// macro, execute at compiletime
  sp_push((cell_t)code);	// push current compilation address for loop
}

// Uncounted loops
static void f_while(void) {	// macro, execute at compiletime
  *code++=xt_1branch;		// compile a jump if not zero
  *code++=(void*)sp_pop();	// jump back to f_begin address
}

static void f_until(void) {	// macro, execute at compiletime
  *code++=xt_0branch;		// compile a jump if not zero
  *code++=(void*)sp_pop();	// jump back to f_begin address
}

static void f_again(void) {	// macro, execute at compiletime, unconditional loop
  *code++=xt_branch;		// compile a jump 
  *code++=(void*)sp_pop();	// jump back to f_begin address
}

// Counted loops: using the return stack!
static void f_do(void){
  *code++ = xt_rppushs;
  sp_push( (cell_t)code );
}

static void rp_clean(void){ rp_pop(); rp_pop();}
static void rp_pushs(void){ rp_push( (xt_t **) sp[-1] ); rp_push( (xt_t **) *sp ); sp_pop(); sp_pop();}
static void sp_pushr(void){
  cell_t limit = (cell_t) rp_pop();
  cell_t curix = (cell_t) rp_pop();
  curix += 1;
  rp_push( (xt_t **) curix );
  rp_push( (xt_t **) limit );
  sp_push( curix );
  sp_push( limit );
}

static void f_i(void){ sp_push( (cell_t) rp[-1]  ); }

static void f_loop(void){
  *code++ = xt_sppushr;
  *code++ = xt_sup;
  *code++ = xt_0branch;
  *code++ = (xt_t *) sp_pop();
  *code++ = xt_rpclean;
}

static void f_unloop(void) {
  rp_clean();
}

static void f_dis(void) {
  xt_t **ip=(void*)sp_pop();
  for(; (*ip)->prim!=f_leave;ip++) {
    xt_t *xt=*ip;
    if(xt->has_lit) {
      printf("%p %s %p\n", ip, xt->name, ip[1]);
      ip++;
    } else {
      printf("%p %s\n", ip, xt->name);
    }
  }
}

static void f_tick(void) {
  char *w=word();
  xt_t *xt=find(dictionary, w);
  if(xt) sp_push((cell_t)xt);
  else   terminate("WU Error"); // work unknown
}

static void f_constant(void){
  char *w=word();
  cell_t  v = (cell_t) sp_pop();
  add_word(w, f_docol);
  *code++ = xt_lit;
  *code++ = (xt_t *)v;
  *code++ = xt_leave;
}

static void f_variable(void){
  char *w=word();
  cell_t  v = (cell_t) sp_pop();
  cell_t  *addr = (cell_t *) MALLOC( sizeof(cell_t) );
  *addr = v;
  add_word(w, f_docol);
  *code++ = xt_lit;
  *code++ = (xt_t *) addr;
  *code++ = xt_leave;
}

static void f_put(void){
  cell_t *addr = (cell_t *) sp_pop();
  cell_t val  = (cell_t) sp_pop();
  *addr = val;
}

static void f_get(void){
  cell_t *addr = (cell_t *) sp_pop();
  sp_push( (cell_t) *addr );
}

static void f_see(void) {
  f_tick();
  xt_t *xt=(xt_t*)(*sp);
  *sp=(cell_t)xt->data;
  f_dis();
}

static void f_execute(void) {
  xt_t *cur=current_xt;
  current_xt=(void*)sp_pop();
  current_xt->prim();
  current_xt=cur;
}

static void f_xt_to_name(void) {
	*sp=(cell_t)((xt_t*)*sp)->name;
}

static void f_xt_to_data(void) {
	*sp=(cell_t)((xt_t*)*sp)->data;
}

static void f_set_stdin(void){
  char *fn = (char*)sp_pop();
  if( S_stdin ) fclose( S_stdin );
  S_stdin = fn ? fopen( fn, "r" ) : NULL;
}

static void f_get_stdin(void){
  sp_push( (cell_t)S_stdin );
}

// EXTENSIONS
// nxm-Arrays:
//    <NCOLS> <NROWS> arr2d --> <ARR2D>
//    <ARR2D> <COL> <ROW> arr2d@ --> <VAL>
//    <ARR2D> <COL> <ROW> <VAL> arr2d! --> nil
typedef struct arr2d_t {
  int rows;
  int cols;
  int *arr2d;
} arr2d_t;

static void f_arr2d_new( void ){
  int rows = (int) sp_pop();
  int cols = (int) sp_pop();
  arr2d_t *arr2d = CALLOC(1, sizeof(arr2d_t));
  arr2d->rows = rows;
  arr2d->cols = cols;
  arr2d->arr2d = (int *) MALLOC( (unsigned long long) rows*cols );
  sp_push( (cell_t) arr2d );
}

static void f_arr2d_get( void ){
  int row		= (int) sp_pop();
  int col		= (int) sp_pop();
  arr2d_t *arr2d	= (arr2d_t *) sp_pop();
  int *bytes		= arr2d->arr2d;
  sp_push( (cell_t) bytes[ row*(arr2d->cols) + col ] );
}

static void f_arr2d_set( void ){
  int val		= (int) sp_pop();
  int row		= (int) sp_pop();
  int col		= (int) sp_pop();
  arr2d_t *arr2d	= (arr2d_t *) sp_pop();
  int *bytes		= arr2d->arr2d;
  bytes[ row*(arr2d->cols) + col ] = val; 
}

// VM, INTERPRETER and COMPILER
// --------------------------------------------------------------------------------
/* 1.1. read next word, finish if imput is empty */
/* 1.2. if compile mode => [show at 2.1 compiling] */
/* 1.3. if word is a string, push string literal */
/* 1.4. else if word is in dictionary, execute word */
/* 1.5. else if word is a number, push number on data stack */
/* 1.6. throw an error, unknown word */

/* 2.1. if word is a string, compile a string literal */
/* 2.2. else if word is a macro, execute word */
/* 2.3. else if word is in dictionary, compile it */
/* 2.4. else if word is a number, compile a number literal */
/* 2.5. throw an error, unknwon word */

/* continue at 1.1. */

static void register_primitives(void) {
  // Utilities:
  add_word("pstack",pstack);
  xt_rpclean = add_word( "rp_clean", rp_clean ); latest->hidden=1;
  xt_rppushs = add_word( "rp_pushs", rp_pushs ); latest->hidden=1;
  xt_sppushr = add_word( "sp_pushr", sp_pushr ); latest->hidden=1;
  
  add_word("+",		f_add);
  add_word("-",		f_sub);
  add_word("/",		f_div);
  add_word("%",		f_mod);
  add_word("*",		f_mul);		//top of stack (TOS) * next of stack => TOS
  add_word("0=",	f_zerop );
  add_word("0<>",	f_nzerop );
  add_word(">0",	f_pos );
  add_word("<0",	f_neg );
  add_word(">=0",	f_poseq );
  add_word("<=0",	f_negeq );
  xt_sup = add_word(">",		f_sup );
  add_word("<",		f_inf );
  add_word(">=",	f_supeq );
  add_word("<=",	f_infeq );

  add_word("and", f_and );
  add_word("or",  f_or);
  add_word("xor", f_xor);
  add_word("not", f_not);

  add_word("constant",  f_constant);
  latest->has_lit=1;
  add_word("variable",  f_variable);
  latest->has_lit=1;

  add_word("!", f_put);
  add_word("@", f_get);
  
  xt_hello = add_word("hello",	f_hello_world); // say hello world
  xt_drop=add_word("drop",	f_drop);	// discard top of stack
  xt_dup=add_word("dup",	f_dup);
  xt_swap=add_word("swap",	f_swap);
  add_word("rot", f_rot);
  add_word("over", f_over);
  add_word("words",		f_words);	// list all defined words
  add_word("type",		f_type);	// course02, output string
  add_word("string=",           f_stringeq);    //
  add_word("accept",            f_accept );
  add_word(".",			f_dot);		// course02, output number
  add_word("cr",		f_cr);		// course02, output CR
  add_word(":",			f_colon);	// course03, define new word, enter compile mode
  add_word("create",		f_create);	// course03, define new word, do not enter compile mode
  add_word(",",                 f_comma);

  add_word("unloop",		f_unloop);	// stop and exit a do loop
  add_word("'",			f_tick);	// ' <word> => execution token on stack
  add_word("execute",		f_execute);	// ' <word> => execution token on stack
  add_word("see",		f_see);		// see <word> list FORTH code for <word>
  add_word("dis",		f_dis);		// dis ( ip--) until leave, disassemble
  latest->hidden=1;
  add_word("xt>data",		f_xt_to_data); latest->hidden=1;
  add_word("xt>name",		f_xt_to_name); latest->hidden=1;
  xt_sstdin =add_word("stdin!", f_set_stdin);
  xt_gstdin =add_word("stdin@", f_get_stdin);

  xt_bye=add_word("bye",			f_bye);
  xt_leave=add_word("leave",			f_leave);
  xt_lit=add_word("lit",			f_lit); latest->hidden=1;
  latest->has_lit=1;
  xt_0branch=add_word("0branch",		f_0branch);	// jump if zero
  latest->has_lit=1; latest->hidden=1;
  xt_1branch=add_word("1branch",		f_1branch);	// jump if not zero
  latest->has_lit=1; latest->hidden=1;
  xt_branch =add_word("branch",			f_branch);	// unconditional jump
  latest->has_lit=1; latest->hidden=1;
  xt_word=add_word("word",			f_word);
  xt_interpreting=add_word("interpreting",	f_interpreting);

  // Extensions
  add_word( "arr2d", f_arr2d_new );
  add_word( "arr2d@",f_arr2d_get );
  add_word( "arr2d!",f_arr2d_set );

  // Immediate words (should be in dictionary w. IMMEDIATE flag)
  /* definitions=&macros; */
  add_word(";",		f_semis);				// course03, end of new word, leave compile mode
  latest->immediate=1;
  add_word("if",	f_if);					// compiles an if condition
  latest->immediate=1;
  add_word("then",	f_then);				// this is the endif
  latest->immediate=1;
  add_word("else",	f_else);
  latest->immediate=1;
  add_word("begin",	f_begin);				// begin of while loop
  latest->immediate=1;
  add_word("while",	f_while);				// begin...while loop (condition at end of loop)
  latest->immediate=1;
  add_word("until",	f_until);				// begin...until loop (condition at end of loop)
  latest->immediate=1;
  add_word("again",	f_again);				// unconditional loop to begin
  latest->immediate=1;
  add_word("do",	f_do);				// unconditional loop to begin
  latest->immediate=1;
  add_word("loop",	f_loop);				// unconditional loop to begin
  latest->immediate=1;
  xt_i = add_word("i",	f_i);				// unconditional loop to begin
  

  /* definitions=&dictionary; */
}


static void compiling(char *w) { // course03
  if(*w=='"') {					// +course02: string handling
    literal((cell_t)STRDUP(w+1));		// compile a literal
  /* } else if((current_xt=find(macros, w))) {	// if word is a macro */
  /*   current_xt->prim();				// execute it immediatly */
  } else if((current_xt=find(dictionary, w))) { // if word is immediate, execute, else add to code block
    if( current_xt->immediate )
      { current_xt->prim(); }
    else
      {  *code++=current_xt; }
  } else {					// not found, may be a number
    char *end;
    int number=STRTOL(w, &end, 0);
    if(*end) terminate("WU Error");		// word unknown
    else literal(number);			// compile a number literal
  }
}

static void interpreting(char *w) {
  if(is_compile_mode) return compiling(w);	// Paradoxically
  if(*w=='"') {					// +course02: string handling
    sp_push((cell_t)to_pad(w+1));		// store the string 
  } else if((current_xt=find(dictionary,w))) {
    current_xt->prim();
  } else {					// not found, may be a number
    char *end;
    int number=STRTOL(w, &end, 0);
    if(*end) terminate("WU Error");
    else sp_push(number);
  }
}

static void vm(void) {
  while(RUNNING) {
    current_xt=*ip++;
    current_xt->prim();
  }
}

int main( int argc, char **argv ) {
  register_primitives();

  // The vm is in FORTH and pre-assembled
  /* : HELLO LIT 0 LIT <file-names> STDIN! */
  /* BEGIN */
  /*     BEGIN WORD DUP */
  /*     IF INTERPRETING AGAIN */
  /*     ELSE DROP STDIN@ */
  /*          IF STDIN! AGAIN */
  /*          ELSE BYE ; */
  
  add_word("shell",f_docol);		// define a new high level word
  xt_t **cold   = code;			// Cold boot entry
  *code++       = xt_hello;		// Banner message
  if( 1 < argc ){			// Push FORTH source files in the command line
    *code++	= xt_lit;
    *code++	= (xt_t *)0;
    for( short i = 1; i < argc; i++ ){
      *code++ = xt_lit;
      *code++ = (xt_t *)STRDUP( argv[i] );
    }
    *code++ = xt_sstdin;
  }

  xt_t **begin	= code;			// save current code pointer for loop back
  *code++	= xt_word;		// get the next word on data stack
  *code++	= xt_dup;
  *code++	= xt_0branch;		// jump to end if top of stack is null
  xt_t **here	= code++;		// forward jump reference
  *code++	= xt_interpreting;	// interpret/compile word on top of stack
  *code++	= xt_branch;		// loop back to begin of this word
  *code++	= (void*)begin;		// Loop back address
  *here		= (void*)code;		// resolve reference
  *code++	= xt_drop;

  *code++       = xt_gstdin;
  *code++       = xt_0branch;
  *code++       = xt_bye;
  *code++	= xt_sstdin;
  *code++	= xt_branch;		// loop back to begin of this word
  *code++	= (void*)begin;		// Loop back address

  ip=cold;				// set instruction pointer
  vm();					// and run the vm

  return 0;
}

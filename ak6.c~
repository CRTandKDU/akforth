/* Experiments in FORTH implementations with a view to the Z80
 * Source: Andreas Klimas [[https://w3group.de/forth_course.html]]
 * See also: `lbforth.c' in same directory for alternative ideas.
 *
 * File: ak5.c
 * By: jmc
 * Date: Friday, August 5, 2022
 */

// Hints:
// M-: (require 'imenu-list)
// M-x imenu-list-minor-mode
#include <stdio.h>

static int RUNNING = 1;
static int errno = 0;

// Some functions are reimplemented (smplistically) to break some dependencies
// ---------------------------------------------------------------------------------

/* Array-based Storage Allocator */
#ifndef MEM_STACK_SIZE
#define MEM_STACK_SIZE 2048
#endif
static size_t   store_base[MEM_STACK_SIZE];
static size_t	*store_end	= store_base+MEM_STACK_SIZE;
static size_t	*store		= store_base;

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
int  isalpha(int c){
  return ((c >= UC('a') && c <= UC('z')) || (c >= UC('A') && c <= UC('Z')) ? 1 : 0); }
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


/* Begin FORTH implementation */
// ---------------------------------------------------------------------------------
typedef unsigned long long cell_t;
typedef struct xt_t { // Execution Token
  struct xt_t *next;
  char *name;
  void (*prim)(void);
  struct xt_t **data; // address into high level code
  int has_lit; // does consume the next ip as literal (0branch, 1branch, lit)
} xt_t;

// DICTIONARY
// ---------------------------------------------------------------------------------
static xt_t *dictionary; 
static xt_t *current_xt; // current xt
static xt_t *latest; // last defined word

// STACK
// ---------------------------------------------------------------------------------
#define DATA_STACK_SIZE 32
static cell_t sp_base[DATA_STACK_SIZE], *sp_end=sp_base+DATA_STACK_SIZE;
static cell_t *sp=sp_base-1;

// CALL RETURN STACK
// ---------------------------------------------------------------------------------
static xt_t *macros;  // course03
static xt_t **definitions=&dictionary; // where to store new words
static xt_t **ip; // course03, instruction pointer
#define RETURN_STACK_SIZE 32
static xt_t **rp_base[RETURN_STACK_SIZE], ***rp_end=rp_base+RETURN_STACK_SIZE;
static xt_t ***rp=rp_base-1;

static xt_t *current_xt; // current xt
static xt_t *xt_dup,
  *xt_swap,
  *xt_drop,
  *xt_interpreting,
  *xt_word,
  *xt_bye,
  *xt_lit,
  *xt_leave,
  *xt_branch,
  *xt_0branch,
  *xt_1branch; // some execution tokens need for compiling

static int is_compile_mode; // course03: we are either interpreting or compiling
#define CODE_SIZE 65536
static xt_t *code_base[CODE_SIZE], **code=code_base, **code_end=code_base+CODE_SIZE;


static xt_t *compile(xt_t *xt) ;
static void interpreting(char *w) ;


// UTILITIES and PARSING INPUT
// ---------------------------------------------------------------------------------
static xt_t *find(xt_t *dict, char *w) { // find word either in dictionary or macros
  for(;dict;dict=dict->next) if(!STRCMP(dict->name, w)) return dict;
  return 0; // not found
}

static void ok(void) { // print data stack, than ok>
  cell_t *i;
  printf( "[%6d / %6d] ", store - store_base, store_end - store_base );
  for(i=sp_base;i<=sp;i++) printf("%d ", *i);
  printf("ok> ");
}

static int next_char(void) {
  static int last_char;
  if(last_char=='\n') ok(); // ok> prompt
  last_char=fgetc(stdin);
  return last_char==EOF?0:last_char;
}

static int skip_space(void) {
  int ch;
  while((ch=next_char()) && isspace(ch));
  return ch;
}

static char *word(void) { // symbol might have maximal 256 bytes
  static char buffer[256], *end=buffer+sizeof(buffer)-1;
  char *p=buffer, ch;
  if(!(ch=skip_space())) return 0; // no more input
  *p++=ch;
  if(ch=='"') { // +course02: string handling
    while(p<end && (ch=next_char()) && ch!='"') *p++=ch;
  } else {
    while(p<end && (ch=next_char()) && !isspace(ch)) *p++=ch;
  }
  *p=0; // zero terminated string
  return buffer;
}

static void terminate(char *msg) {
  fprintf(stderr, "terminated: %s\n", msg);
  RUNNING = 0;
}

static char *to_pad(char *str) { // add for course02: copy str into scratch pad
  static char scratch[1024];
  int i = 0, len;
  while( str[i] != '\0' ) ++i; len = (size_t)i; // strlen
  if(len>sizeof(scratch)-1) len=sizeof(scratch)-1;
  for( i=0; i<=len; i++ ) scratch[i] = str[i]; // memcpy
  scratch[len]=0; // zero byte at string end
  return scratch;
}

// DICTIONARY OPERATIONS
// ---------------------------------------------------------------------------------
static xt_t *add_word(char *name, void (*prim)(void)) {
  xt_t *xt=CALLOC(1, sizeof(xt_t));
  if( NULL == xt ){
    terminate( "OM Error" );
  }
  else{
    xt->next = *definitions;
    *definitions = xt;
    xt->name = STRDUP(name);
    xt->prim = prim;
    xt->data = code; // current high level code pointer, compilation target
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

static void f_hello_world(void) {
  printf("Hello World\n");
}

static void f_bye(void){ RUNNING = 0; }

static void f_drop(void) {sp_pop();} // drop top of stack

static void f_words(void) { // display all defined words
  xt_t *w;
  for(w=dictionary;w;w=w->next) printf("%s ", w->name);
  printf("\n");
}

static void f_dot(void) {
  printf("%d ", sp_pop());
}

static void f_type(void){ // course02
  fputs((char*)sp_pop(), stdout);
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

static void f_colon(void) { // course03, define a new word
  char *w=word(); // read next word which becomes the word name
  add_word(STRDUP(w), f_docol);
  is_compile_mode=1; // switch to compile mode
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

static void f_if(void) { // macro, execute at compiletime
  *code++=xt_0branch;
  sp_push((cell_t)code++); // push forward reference on stack
}

static void f_else(void) { // macro, execute at compiletime
  xt_t ***dest=(void*)sp_pop(); // pop address (from f_if) 
  *code++=xt_branch; // compile a jump
  sp_push((cell_t)code++); 
  *dest=code; 
}

static void f_then(void) { // macro, execute at compiletime
  xt_t ***dest=(void*)sp_pop();
  *dest=code; // resolve forward reference given by f_if or f_else
}
static void f_begin(void) { // macro, execute at compiletime
  sp_push((cell_t)code); // push current compilation address for loop
}
static void f_while(void) { // macro, execute at compiletime
  *code++=xt_1branch; // compile a jump if not zero
  *code++=(void*)sp_pop(); // jump back to f_begin address
}
static void f_again(void) { // macro, execute at compiletime, unconditional loop
  *code++=xt_branch; // compile a jump 
  *code++=(void*)sp_pop();// jump back to f_begin address
}

static void f_exit(void) { ip=rp_pop(); }

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
  add_word("+",			f_add);
  add_word("-",			f_sub);
  add_word("/",			f_div);
  add_word("%",			f_mod);
  add_word("*",			f_mul);//top of stack (TOS) * next of stack => TOS
  add_word("hello",		f_hello_world); // say hello world
  xt_drop=add_word("drop",	f_drop); // discard top of stack
  xt_dup=add_word("dup",	f_dup);
  xt_swap=add_word("swap",	f_swap);
  add_word("words",		f_words); // list all defined words
  add_word("type",		f_type); // course02, output string
  add_word(".",			f_dot); // course02, output number
  add_word("cr",		f_cr); // course02, output CR
  add_word(":",			f_colon); // course03, define new word, enter compile mode

  add_word("exit",	f_exit); // same as leave but leave is used to recognize the end of assembling
  add_word("'",		f_tick); // ' <word> => execution token on stack
  add_word("execute",	f_execute); // ' <word> => execution token on stack
  add_word("see",	f_see); // see <word>
  add_word("dis",	f_dis); // dis ( ip--) until leave
  add_word("xt>data",	f_xt_to_data);
  add_word("xt>name",	f_xt_to_name);


  xt_bye=add_word("bye",			f_bye);
  xt_leave=add_word("leave",			f_leave);
  xt_lit=add_word("lit",			f_lit);
  latest->has_lit=1;
  xt_0branch=add_word("0branch",		f_0branch); // jump if zero
  latest->has_lit=1;
  xt_1branch=add_word("1branch",		f_1branch); // jump if not zero
  latest->has_lit=1;
  xt_branch =add_word("branch",			f_branch); // unconditional jump
  latest->has_lit=1;
  xt_word=add_word("word",			f_word);
  xt_interpreting=add_word("interpreting",	f_interpreting);

  definitions=&macros;
  add_word(";",		f_semis); // course03, end of new word, leave compile mode
  add_word("if",	f_if);    // compiles an if condition
  add_word("then",	f_then);  // this is the endif
  add_word("else",	f_else);
  add_word("begin",	f_begin); // begin of while loop
  add_word("while",	f_while); // while loop (condition at end of loop)
  add_word("again",	f_again); // unconditional loop to begin

  definitions=&dictionary;
}


static void compiling(char *w) { // course03
  if(*w=='"') { // +course02: string handling
    literal((cell_t)STRDUP(w+1)); // compile a literal
  } else if((current_xt=find(macros, w))) { // if word is a macro
    current_xt->prim();  // execute it immediatly
  } else if((current_xt=find(dictionary, w))) { // if word is regular
    *code++=current_xt;  // dictionary, compile it
  } else { // not found, may be a number
    char *end;
    int number=STRTOL(w, &end, 0);
    if(*end) terminate("WU Error"); // word unknown
    else literal(number); // compile a number literal
  }
}

static void interpreting(char *w) {
  if(is_compile_mode) return compiling(w); // Paradoxically
  if(*w=='"') { // +course02: string handling
    sp_push((cell_t)to_pad(w+1)); // store the string 
  } else if((current_xt=find(dictionary,w))) {
    current_xt->prim();
  } else { // not found, may be a number
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

int main() {
  register_primitives();

  /* we compile interpreting by hand */
  add_word("shell",f_docol);// define a new high level word
  xt_t **begin	= code;       // save current code pointer for loop back
  *code++	= xt_word;         // get the next word on data stack
  *code++	= xt_dup;
  *code++	= xt_0branch;      // jump to end if top of stack is null
  xt_t **here	= code++;      // forward jump reference
  *code++	= xt_interpreting; // interpret/compile word on top of stack
  *code++	= xt_branch;       // loop back to begin of this word
  *code++	= (void*)begin;    // Loop back address
  *here		= (void*)code;       // resolve reference
  *code++	= xt_drop;
  *code++	= xt_bye;          // leave VM

  ip=begin;                // set instruction pointer
  vm();                    // and run the vm

  return 0;
}

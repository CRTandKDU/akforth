/* Experiments in FORTH implementations with a view to the Z80
 * Source: Andreas Klimas [[https://w3group.de/forth_course.html]]
 * See also: `lbforth.c' in same directory for alternative ideas.
 *
 * File: ak2.c
 * By: jmc
 * Date: Thursday, August 4, 2022
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
#define MEM_STACK_SIZE 1024
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
} xt_t;

// DICTIONARY
// ---------------------------------------------------------------------------------
static xt_t *dictionary; 
static xt_t *current_xt; // current xt

// STACK
// ---------------------------------------------------------------------------------
#define DATA_STACK_SIZE 32
static cell_t sp_base[DATA_STACK_SIZE], *sp_end=sp_base+DATA_STACK_SIZE;
static cell_t *sp=sp_base-1;

// UTILITIES and PARSING INPUT
// ---------------------------------------------------------------------------------
static xt_t *find(char *w) { // find word in dictionary
  xt_t *xt;
  for(xt=dictionary;xt;xt=xt->next) if(!STRCMP(xt->name, w)) return xt;

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
static void add_word(char *name, void (*prim)(void)) {
  xt_t *xt=CALLOC(1, sizeof(xt_t));
  if( NULL == xt ){
    terminate( "OM Error" );
  }
  else{
    xt->next=dictionary;
    dictionary=xt;
    xt->name=STRDUP(name);
    xt->prim=prim;
  }
}

// STACK OPERATIONS
// ---------------------------------------------------------------------------------
static void sp_push(cell_t value) {
  if(sp==sp_end) terminate("Data stack overflow");
  *++sp=value;
}

static cell_t sp_pop(void) {
  if(sp<sp_base) terminate("Data stack underrun");
  return *sp--;
}

// PRIMITIVES and BUILTINS
// ---------------------------------------------------------------------------------
static void f_mul(void) {
  int v1=sp_pop();
  *sp *= v1;
}

static void f_add(void) {
  int v1=sp_pop();
  *sp += v1;
}

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


// VM, INTERPRETER and COMPILER
// ---------------------------------------------------------------------------------
static void register_primitives(void) {
  add_word("+",		f_add);
  add_word("*",		f_mul);
  add_word("hello",	f_hello_world);
  add_word("bye",	f_bye);
  add_word("drop",	f_drop);
  add_word("words",	f_words);
  add_word(".",		f_dot);
  add_word("type",	f_type); // course02
  add_word("cr",	f_cr); // course02
}


static void interpret(char *w) {
	if(*w=='"') { // +course02: string handling
		sp_push((cell_t)to_pad(w+1)); // store the string 
	} else if((current_xt=find(w))) {
		current_xt->prim();
	} else { // not found, may be a number
		char *end;
		int number=STRTOL(w, &end, 0);
		if(*end) terminate("word not found");
		else sp_push(number);
	}
}

int main() {
  register_primitives();

  char *w;
  while( RUNNING && (w=word()) ) interpret(w);
  return 0;
}

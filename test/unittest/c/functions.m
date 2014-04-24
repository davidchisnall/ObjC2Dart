#include <stdarg.h>

// A function declaration (should not be translated).

void decl();

// Functions of various types.

void void_f() {
}

int int_f() {
  return 1;
}

// Function with int arguments.

void args(int a, int b) {
}

// Function with pointer arguments.

void argsp(int *a, int *b) {
}

// Functions with array arguments.

void argsa1(int a[], int b[]) {
}

void argsa2(int a[1], int b[2]) {
}

// Function calling other functions.

int call() {
  void_f();
// TODO: enable this when assignment/initialization is done properly.
#if 0
  int x = 1;
  args(0, x);
#else
  args(0, 1);
#endif
  return int_f();
}

// TODO: enable this when variadic functions are working.
#if 0
// Variadic functions.

void implicit_varargs() {
}

void varargs1(int a, ...) {
  va_list list;
  va_start(list, a);
  void *b = va_arg(list, void *);
  int *c = va_arg(list, int *);
  va_end(list);
}

void varargs2(int a, int b, ...) {
  va_list list;
  va_start(list, b);
  va_start(list, a);
  va_end(list);
}
#endif

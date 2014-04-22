#include <stdarg.h>

// Takes a number of int arguments and returns the n-th one in the variadic
// argument list.
int argN(int n, ...) {
  va_list ap;
  va_start(ap, n);
  int arg = va_arg(ap, int);
  for (int i = 0; i < n; ++i) {
    arg = va_arg(ap, int);
  }
  va_end(ap);
  return arg;
}


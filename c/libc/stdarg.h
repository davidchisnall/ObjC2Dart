#ifndef STDARG_H
#define STDARG_H

#include <libc.h>

typedef __objc2dart__dart_class va_list;

// There will be only one argument of type int after ap, specifying the position
// of the argument to start the list at.
void va_start(va_list ap, ...);

// Return the next argument in the list.
void *va_arg(va_list ap);
#define va_arg(AP, TYPE) (*((TYPE *)va_arg(AP)))

#define va_end(AP)

#endif /* STDARG_H */

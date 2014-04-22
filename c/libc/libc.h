#ifndef LIBC_H
#define LIBC_H

/**
 * This tells objc2dart that the type that is typedef'd to this is a dart class
 * and it should be emitted as-is.
 *
 * Example: typedef __objc2dart__dart_class num;
 */
typedef struct {} __objc2dart__dart_class;

/**
 * Size type.
 */
typedef int size_t;

#endif /* LIBC_H */

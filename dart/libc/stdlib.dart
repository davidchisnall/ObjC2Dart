import '../c/types.dart';

/**
 * Allocates |bytes| bytes of memory.
 * Returns a pointer to the newly allocated memory.
 */
C__TYPE_Pointer C__malloc(int bytes) {
  return new C__TYPE_Pointer.toMemory(new C__Memory(bytes), 0);
}

/**
 * C declaration: void * malloc (size_t size);
 */
C__TYPE_Pointer malloc(C__TYPE_Int64 size) => C__malloc(size.view.getInt64(0));

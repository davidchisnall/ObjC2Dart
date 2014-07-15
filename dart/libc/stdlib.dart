import '../c/types.dart';

/**
 * Allocates |bytes| bytes of memory.
 * Returns a pointer to the newly allocated memory.
 */
C__TYPE_Pointer C__malloc(int bytes) {
  return new C__TYPE_Pointer.toMemory(new DartCMemory(bytes), 0);
}

/**
 * C declaration: void * malloc (size_t size);
 */
C__TYPE_Pointer malloc(DartCInteger size) => C__malloc(size.view.getInt64(0));

/**
 * Frees memory allocated with malloc.
 * C declaration: void free(void * ptr);
 */
void free(C__TYPE_Pointer ptr) {
  dartCMemoryMap[ptr.memoryPointedTo.baseAddress] = null;
}

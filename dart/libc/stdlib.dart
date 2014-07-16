import '../c/types.dart';


/**
 * C declaration: void * malloc (size_t size);
 */
DartCPointer malloc(DartCInteger size) =>
    (new DartCComposite.alloc(size.intValue())).addressOf();

/**
 * Frees memory allocated with malloc.
 * C declaration: void free(void * ptr);
 *
 * Note that this does not destroy the underlying object, it merely makes it
 * impossible to subsequently cast an integer to this object.
 */
void free(DartCPointer ptr) {
  ptr.baseObject.memory.free();
}

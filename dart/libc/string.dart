import '../c/types.dart';

/**
 * Copies |num| bytes of memory from |source| to |destination|.
 * Returns |destination|.
 */
DartCPointer C__memcpy(DartCPointer destination, DartCPointer source, DartCInteger num) {
  DartCObject dest = destination.dereference();
  DartCObject src = source.dereference();
  int bytes = num.intValue();
  dest.memory.memcpy(src.memory, dest.offset, src.offset, bytes);
  return destination;
}

/**
 * Sets |num| bytes of memory starting at |ptr| to |value|.
 * Returns |ptr|.
 */
DartCPointer C__memset(DartCPointer ptr, DartCInteger value, DartCInteger len) {
  DartCObject dest = ptr.dereference();
  int bytes = len.intValue();
  int byte = value.intValue().toSigned(8);
  for (int i = 0; i < bytes; ++i) {
    dest.memory.setInt8(i, byte);
  }
  return ptr;
}

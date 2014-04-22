import '../c/types.dart';

/**
 * Copies |num| bytes of memory from |source| to |destination|.
 * Returns |destination|.
 */
C__TYPE_Pointer C__memcpy(C__TYPE_Pointer destination, C__TYPE_Pointer source, int num) {
  for (int i = 0; i < num; ++i) {
    destination.pointee.view.setInt8(i, source.pointee.view.getInt8(i));
  }
  return destination;
}

/**
 * Sets |num| bytes of memory starting at |ptr| to |value|.
 * Returns |ptr|.
 */
C__TYPE_Pointer C__memset(C__TYPE_Pointer ptr, int value, int num) {
  for (int i = 0; i < num; ++i) {
    ptr.pointee.view.setInt8(i, value);
  }
  return ptr;
}

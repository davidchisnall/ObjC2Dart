import '../c/types.dart';

/**
 * C declaration: void * malloc (size_t size);
 */
C__TYPE_Pointer malloc(C__TYPE_Int64 size) => C__malloc(size.getLiteral());

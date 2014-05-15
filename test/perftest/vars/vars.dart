import 'package:this/c/types.dart';
import 'package:this/libc/stdarg.dart';

void test(C__TYPE_Int64 n) {
  C__TYPE_Int64 a = new C__TYPE_Int64.local();
  C__TYPE_Pointer p = new C__TYPE_Pointer.local(C__TYPE_DEFINITION.int64_t);
  for (C__TYPE_Int64 i = (new C__TYPE_Int64.literal(0)); i < n; i.inc()) {
    a.set(i);
    C__TYPE_Int64 b = i;
    p.set(b.pointer());
  }
  ;
}

import 'package:this/c/types.dart';
import 'package:this/libc/stdlib.dart';
import 'package:this/libc/stdarg.dart';

C__TYPE_Int64 binsearch(C__TYPE_Pointer v, C__TYPE_Int64 n, C__TYPE_Int64 s) {
  C__TYPE_Int64 p = new C__TYPE_Int64.local();
  for (p.set((new C__TYPE_Int64.literal(1))); p < n; p.set(p.shl((new C__TYPE_Int64.literal(1))))) ;
  C__TYPE_Int64 r = new C__TYPE_Int64.local();
  for (r.set((new C__TYPE_Int64.literal(0))); p > (new C__TYPE_Int64.literal(0)); p.set(p.shr((new C__TYPE_Int64.literal(1))))) {
    if (r + p < n && v.index(r + p) <= s) {
      r.set(r + p);
    }
     else {
    }
    ;
  }
  ;
  return r;
}
void test(C__TYPE_Int64 n) {
  C__TYPE_Pointer v = malloc(n * (new C__TYPE_Int64.literal(8)));
  for (C__TYPE_Int64 i = (new C__TYPE_Int64.literal(0)); i < n; i.inc()) {
    v.index(i).set(i);
  }
  ;
  C__TYPE_Int64 p = binsearch(v, n, n / (new C__TYPE_Int64.literal(3)));
  free(v);
}

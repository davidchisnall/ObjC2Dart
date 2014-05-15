import 'package:this/c/types.dart';
import 'package:this/libc/stdlib.dart';
import 'package:this/libc/stdarg.dart';

void test(C__TYPE_Int64 n) {
  C__TYPE_Pointer v = malloc(n * (new C__TYPE_Int64.literal(8)));
  for (C__TYPE_Int64 i = (new C__TYPE_Int64.literal(0)); i < n; i.inc()) {
    v.index(i).set(i);
  }
  ;
  C__TYPE_Int64 e = n - (new C__TYPE_Int64.literal(1));
  for (C__TYPE_Int64 i = (new C__TYPE_Int64.literal(0)); i < e; i.inc()) {
    v.index(i).set(v.index(i + (new C__TYPE_Int64.literal(1))));
  }
  ;
}

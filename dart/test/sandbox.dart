import 'package:this/c/types.dart';
import 'package:this/libc/stdlib.dart';
import 'package:this/libc/stdarg.dart';

import 'package:this/c/types.dart';
import 'dart:io';

C__TYPE_Int64 binsearch(C__TYPE_Pointer v, C__TYPE_Int64 start, C__TYPE_Int64 end, C__TYPE_Int64 s) {
  if (start == end) {
    return start;
  }
   else ;
  C__TYPE_Int64 middle = start + end / (new C__TYPE_Int64.literal(2));
  if (v.index(middle) < s) {
    return binsearch(v, middle + (new C__TYPE_Int64.literal(1)), end, s);
  }
   else {
    return binsearch(v, start, middle, s);
  }
  ;
}
void test(C__TYPE_Int64 n) {
  C__TYPE_Pointer v = malloc(n * (new C__TYPE_Int64.literal(8)));
  for (C__TYPE_Int64 i = (new C__TYPE_Int64.literal(0)); i < n; i.inc()) {
    v.index(i).set(i);
  }
  ;
  C__TYPE_Int64 p = binsearch(v, (new C__TYPE_Int64.literal(0)), n, n / (new C__TYPE_Int64.literal(3)));
  free(v);
}


void main() {
  DateTime t = new DateTime.now();
  test(new C__TYPE_Int64.literal(200));
  stdout.write("${(new DateTime.now()).difference(t).inMilliseconds} ");
}

import 'package:this/c/types.dart';
import 'package:this/libc/stdlib.dart';
import 'package:this/libc/stdarg.dart';
import 'package:this/objc/NSObject.dart';

void test(C__TYPE_Int64 n) {
  for (C__TYPE_Int64 i = (new C__TYPE_Int64.literal(0)); i < n; i.inc()) {
    NSObject o = NSObject.alloc().init();
  }
  ;
}

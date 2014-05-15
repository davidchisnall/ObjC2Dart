import 'package:this/c/types.dart';
import 'package:this/libc/stdarg.dart';

void void_f() {
}
C__TYPE_Int64 int_f() {
  return (new C__TYPE_Int64.literal(1));
}
void args(C__TYPE_Int64 a, C__TYPE_Int64 b) {
}
void argsp(C__TYPE_Pointer a, C__TYPE_Pointer b) {
}
void argsa1(C__TYPE_Pointer a, C__TYPE_Pointer b) {
}
void argsa2(C__TYPE_Pointer a, C__TYPE_Pointer b) {
}
C__TYPE_Int64 call() {
  void_f();
  C__TYPE_Int64 x = (new C__TYPE_Int64.literal(1));
  args((new C__TYPE_Int64.literal(0)), x);
  return int_f();
}
void main() {
  {
    return (new C__TYPE_Int64.literal(0));
  }
  main();
}

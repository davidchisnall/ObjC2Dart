import 'package:this/c/types.dart';
void void_f() {
}
C__TYPE_Int64 int_f() {
  return (new C__TYPE_IntegerLiteral(1));
}
void args(C__TYPE_Int64 a, C__TYPE_Int64 b) {
}
C__TYPE_Int64 call() {
  void_f();
  args((new C__TYPE_IntegerLiteral(0)), (new C__TYPE_IntegerLiteral(1)));
  return int_f();
}

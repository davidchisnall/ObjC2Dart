import 'package:this/libc/stdarg/stdarg.dart';

import 'package:unittest/unittest.dart';

// Returns the first argument.
class C__VARARGS_FUNCTION__firstArgument extends C__VARARGS_FUNCTION {
  dynamic body(List arguments) {
    return arguments[0];
  }
}
Object C__VARARGS__firstArgument = new C__VARARGS_FUNCTION__firstArgument();

void main() {
  group('firstArgument', () {
    test('firstArgument()', () => expect(() => C__VARARGS__firstArgument(), throws));
    test('firstArgument(0)', () => expect(C__VARARGS__firstArgument(0), equals(0)));
    test('firstArgument(1, 2)', () => expect(C__VARARGS__firstArgument(1, 2), equals(1)));
    test('firstArgument(3, 4, 5)', () => expect(C__VARARGS__firstArgument(3, 4, 5), equals(3)));
  });
}

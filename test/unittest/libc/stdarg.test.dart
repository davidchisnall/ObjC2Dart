import 'stdarg.dart';

import 'package:this/c/types.dart';
import 'package:unittest/unittest.dart';

void main() {
  var expectValue = (C__TYPE actual, num expected) {
      expect(actual.view.getInt64(0), equals(expected));
  };
  test('Varargs', () {
    expectValue(argN(new C__TYPE_Int64.literal(0), new C__TYPE_Int64.literal(1),
        new C__TYPE_Int64.literal(2), new C__TYPE_Int64.literal(3), new C__TYPE_Int64.literal(4),
        new C__TYPE_Int64.literal(5)), 1);
    expectValue(argN(new C__TYPE_Int64.literal(1), new C__TYPE_Int64.literal(1),
        new C__TYPE_Int64.literal(2), new C__TYPE_Int64.literal(3), new C__TYPE_Int64.literal(4),
        new C__TYPE_Int64.literal(5)), 2);
    expectValue(argN(new C__TYPE_Int64.literal(2), new C__TYPE_Int64.literal(1),
        new C__TYPE_Int64.literal(2), new C__TYPE_Int64.literal(3), new C__TYPE_Int64.literal(4),
        new C__TYPE_Int64.literal(5)), 3);
    expectValue(argN(new C__TYPE_Int64.literal(3), new C__TYPE_Int64.literal(1),
        new C__TYPE_Int64.literal(2), new C__TYPE_Int64.literal(3), new C__TYPE_Int64.literal(4),
        new C__TYPE_Int64.literal(5)), 4);
    expectValue(argN(new C__TYPE_Int64.literal(4), new C__TYPE_Int64.literal(1),
        new C__TYPE_Int64.literal(2), new C__TYPE_Int64.literal(3), new C__TYPE_Int64.literal(4),
        new C__TYPE_Int64.literal(5)), 5);
  });
}

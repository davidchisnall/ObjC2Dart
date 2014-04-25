import 'comma-separated-expressions.dart';

import 'package:unittest/unittest.dart';

void main() {
  var expectValue = (C__TYPE actual, num expected) {
      expect(actual.view.getInt64(0), equals(expected));
  };
  test('CSE', () { expectValue(cse(), 2); });
}

import 'type-functionality.dart';

import 'package:unittest/unittest.dart';

void main() {
  var expectValue = (C__TYPE actual, num expected) {
      expect(actual.view.getInt64(0), equals(expected));
  };
  test('AssignLiteral1', () { expectValue(testAssignLiteral1(), 1); });
  test('AssignLiteral2', () { expectValue(testAssignLiteral2(), 2); });
  test('AssignVariable', () { expectValue(testAssignVariable(), 3); });
  test('ReturnLiteral', () { expectValue(testReturnLiteral(), 4); });
  test('ReturnVariable', () { expectValue(testReturnVariable(), 5); });
  test('MultipleAssign', () { expectValue(testMultipleAssign(), 6); });
}

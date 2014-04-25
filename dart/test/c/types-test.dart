import 'package:this/c/types.dart';

import 'package:unittest/unittest.dart';

void main() {
  group('IntegerLiteral', () {
    test('Allocate and check signs', () {
      var testLiteral = (literal) {
        C__TYPE_Int64 a = new C__TYPE_Int64.literal(literal);
        expect(a.view.getInt64(0), equals(literal));
      };
      testLiteral(10);
      testLiteral(-10);
      testLiteral(343597383680);
      testLiteral(-343597383680);
    });
  });
  group('Int64', () {
    test('Allocate and assign literals', () {
      var testLiteral = (literal) {
        C__TYPE_Int64 a = C__TYPE_DEFINITION.int64_t.at(
            new C__Memory(C__TYPE_DEFINITION.int64_t.byteSize), 0);
        a.set(new C__TYPE_Int64.literal(literal));
        expect(a.view.getInt64(0), equals(literal));
      };
      testLiteral(10);
      testLiteral(-10);
      testLiteral(343597383680);
      testLiteral(-343597383680);
    });
  });
}

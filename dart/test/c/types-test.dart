import 'package:this/c/types.dart';

import 'package:unittest/unittest.dart';

void main() {
  group('int64', () {
    test('Allocate and assign a literal', () {
      C__TYPE_Int64 a = C__TYPE_DEFINITION.int64_t.create(
          new C__Memory(C__TYPE_DEFINITION.int64_t.byteSize), 0);
      a.setLiteral(10);
      expect(a.getLiteral(), equals(10));
    });
  });
}
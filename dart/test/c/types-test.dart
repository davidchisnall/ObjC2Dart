import '../../libc/libc.dart';

import 'package:unittest/unittest.dart';

void main() {
  group('IntegerLiteral', () {
    test('Allocate and check signs', () {
      var testLiteral = (literal) {
        DartCSignedLong a = new DartCSignedLong.fromInt(literal);
        expect(a.intValue(), equals(literal));
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
        DartCSignedLong a = new DartCSignedLong();
        a.set(new DartCSignedLong.fromInt(literal));
        expect(a.intValue(), equals(literal));
      };
      testLiteral(10);
      testLiteral(-10);
      testLiteral(343597383680);
      testLiteral(-343597383680);
    });
  });
  group('Pointers', () {
    test('int * - creation, deref, set', () {
      // Define 2 integers, |a| and |b|.
      DartCSignedLong a = new DartCSignedLong.fromInt(3);
      expect(a.intValue(), equals(3));
      DartCSignedLong b = new DartCSignedLong.fromInt(5);
      expect(b.intValue(), equals(5));

      // Define a pointer to |a|.
      DartCPointer p = a.addressOf();
      expect(p.intValue(), equals(a.address));
      expect(p.dereference(), equals(a));

      // Check that dereferencing and setting affects |a|, but not |b|.
      p.dereference().set(new DartCSignedLong.fromInt(7));
      expect(a.intValue(), equals(7));
      expect(b.intValue(), equals(5));

      // Make |p| point to |b|.
      p.set(b.addressOf());
      expect(p.intValue(), equals(b.address));
      expect(p.dereference(), equals(b));

      // Check that the pointer assignment did not affect |a| and |b|.
      expect(a.intValue(), equals(7));
      expect(b.intValue(), equals(5));
    });
  });
}

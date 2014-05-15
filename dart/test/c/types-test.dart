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
  group('Pointers', () {
    test('int * - creation, deref, set', () {      
      // Define 2 integers, |a| and |b|.
      C__TYPE_Int64 a = new C__TYPE_Int64.literal(3);
      expect(a.view.getInt64(/* at offset */ 0), equals(3));
      C__TYPE_Int64 b = new C__TYPE_Int64.literal(5);
      expect(b.view.getInt64(0), equals(5));
      
      // Define a pointer to |a|.
      C__TYPE_Pointer p = a.pointer();
      expect(p.view.getInt64(0), equals(a.address));
      expect(p.pointee, equals(a));
      
      // Check that dereferencing and setting affects |a|, but not |b|.
      p.pointee.set(new C__TYPE_Int64.literal(7));
      expect(a.view.getInt64(0), equals(7));
      expect(b.view.getInt64(0), equals(5));
      
      // Make |p| point to |b|.
      p.set(b.pointer());
      expect(p.view.getInt64(0), equals(b.address));
      expect(p.pointee, equals(b));
      
      // Check that the pointer assignment did not affect |a| and |b|.
      expect(a.view.getInt64(0), equals(7));
      expect(b.view.getInt64(0), equals(5));
    });
  });
}

import '../libc/libc.dart';

import 'dart:io';

DartCSignedInt binsearch(DartCPointer v, DartCSignedInt n, DartCSignedInt s) {
  DartCSignedInt p = new DartCSignedInt();
  for (p.set((new DartCSignedInt.fromInt(1))); (p < (n)).intValue() != 0; p.set(
      p << ((new DartCSignedInt.fromInt(1)))));
  DartCSignedInt r = new DartCSignedInt();
  for (r.set((new DartCSignedInt.fromInt(0))); (p >
      ((new DartCSignedInt.fromInt(0)))).intValue() != 0; p.set(p >>
      ((new DartCSignedInt.fromInt(1))))) {
    if ((r + (p) < (n).and(v.index(r + (p)) <= (s))).intValue() != 0) {
      {
        r.set(r + (p));
      }

    } else {
      {
      }

    }

  }

  return (r).copy();
}
void test(DartCSignedInt n) {
  DartCPointer v = (malloc(((n).unsignedLongValue() *
      ((new DartCUnsignedLong.fromInt(4)))).copy())).signedIntPointerCast();
  for (DartCSignedInt i = (new DartCSignedInt.fromInt(0)); (i < (n)).intValue()
      != 0; i.inc()) {
    v.index(i).set(i);
  }

  DartCSignedInt p = binsearch((v).copy(), (n).copy(), (n /
      ((new DartCSignedInt.fromInt(3)))).copy());
  free(((v).unsignedCharPointerCast()).copy());
}



void main() {
  DateTime t = new DateTime.now();
  test(new DartCSignedInt.fromInt(200));
  stdout.write("${(new DateTime.now()).difference(t).inMilliseconds} ");
}

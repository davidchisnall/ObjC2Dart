import '../libc/libc.dart';

import 'dart:io';

DartCSignedLong binsearch(DartCPointer v, DartCSignedLong start, DartCSignedLong end, DartCSignedLong s) {
  if (start == end) {
    return start;
  }
   else ;
  DartCSignedLong middle = start + end / (new DartCSignedLong.fromInt(2));
  if (v.index(middle) < s) {
    return binsearch(v, middle + (new DartCSignedLong.fromInt(1)), end, s);
  }
   else {
    return binsearch(v, start, middle, s);
  }
  ;
}
void test(DartCSignedLong n) {
  DartCPointer v = malloc(n * (new DartCSignedLong.fromInt(8)));
  for (DartCSignedLong i = (new DartCSignedLong.fromInt(0)); i < n; i.inc()) {
    v.index(i).set(i);
  }
  ;
  DartCSignedLong p = binsearch(v, (new DartCSignedLong.fromInt(0)), n, n / (new DartCSignedLong.fromInt(3)));
  free(v);
}


void main() {
  DateTime t = new DateTime.now();
  test(new DartCSignedLong.fromInt(200));
  stdout.write("${(new DateTime.now()).difference(t).inMilliseconds} ");
}

import 'vars-hand.dart';

import 'package:this/c/types.dart';
import 'dart:io';

void main() {
	DateTime t = new DateTime.now();
	test(new C__TYPE_Int64.literal(10000));
	stdout.write("${(new DateTime.now()).difference(t).inMilliseconds} ");
}

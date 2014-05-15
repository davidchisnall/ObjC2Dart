import 'vars.dart';

import 'package:this/c/types.dart';
import 'dart:io';

void main() {
	DateTime t = new DateTime.now();
	test(new C__TYPE_Int64.literal(_N_));
	stdout.write("${(new DateTime.now()).difference(t).inMilliseconds} ");
}

import 'package:this/c/types.dart';
import 'package:this/libc/stdarg.dart';

void test(C__TYPE_Int64 aN) {
	int n = aN.view.getInt64(0);
	int a, b;
	int p;
	for (int i = 0; i < n; ++i) {
		a = i;
		b = i;
		p = b;
	}
}

void test(int n) {
	int a, b;
	int *p;
	for (int i = 0; i < n; ++i) {
		a = i;
		b = a;
		p = &b;
	}
}

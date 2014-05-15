#include <stdlib.h>

int binsearch(int *v, int n, int s) {
	int p;
	for (p = 1; p < n; p = p << 1);
	int r;
	for (r = 0; p > 0; p = p >> 1) {
		if (r + p < n && v[r + p] <= s) {
			r = r + p;
		} else {
		}
	}
	return r;
}

void test(int n) {
	// Create array
	int *v = malloc(n * sizeof(int));
	for (int i = 0; i < n; ++i) {
		v[i] = i;
	}
	int p = binsearch(v, n, n / 3);
	free(v);
}

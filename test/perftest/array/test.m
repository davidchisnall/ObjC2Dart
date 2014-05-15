#include <stdlib.h>

void test(int n) {
	// Create array
	int *v = malloc(n * sizeof(int));
	for (int i = 0; i < n; ++i) {
		v[i] = i;
	}
	int e = n - 1;
	for (int i = 0; i < e; ++i) {
		v[i] = v[i + 1];
	}
}

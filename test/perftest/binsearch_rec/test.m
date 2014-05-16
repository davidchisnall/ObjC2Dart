#include <stdlib.h>

int binsearch(int *v, int start, int end, int s) {
	if (start == end) {
		return start;
	}
	int middle = start + end;
	middle = middle / 2;
	if (v[middle] < s) {
		return binsearch(v, middle + 1, end, s);
	} else {
		return binsearch(v, start, middle, s);
	}
}

void test(int n) {
	// Create array
	int *v = malloc(n * sizeof(int));
	for (int i = 0; i < n; ++i) {
		v[i] = i;
	}
	int p = binsearch(v, 0, n, n / 3);
	free(v);
}

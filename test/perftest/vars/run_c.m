#include <stdio.h>
#include <time.h>

#include "vars.h"

int main () {
  clock_t t;
  t = clock();
  test(1e4);
  t = clock() - t;
  printf ("%f ",(((float)t)/CLOCKS_PER_SEC) * 1000);
  return 0;
}

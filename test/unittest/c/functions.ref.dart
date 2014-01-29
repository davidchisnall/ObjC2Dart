void void_f() {
}
int int_f() {
  return 1;
}
void args(int a, int b) {
}
int call() {
  void_f();
  args(0, 1);
  return int_f();
}

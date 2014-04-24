// Test if the typedef chain is properly followed.
typedef int int_1;
typedef int_1 int_2;
typedef int_2 int_3;

// Test if the typedef chain following stops at __objc2dart__dart_class.
typedef struct {} __objc2dart__dart_class;
typedef __objc2dart__dart_class class_1;
typedef class_1 class_2;
typedef class_2 class_3;

// Only functions can have void types, so here's a function (not just a
// declaration, since those are stripped).
void f() {}

int main() {
  // Builtin types.
  int i;

  // Pointer types.
  int *pInt;
  void *pVoid;

  // Typedefs.
  int_1 i1;
  int_2 i2;
  __objc2dart__dart_class c;
  class_1 c1;
  class_2 c2;
  class_3 c3;

  // Comma separated.
  int i3, i4;
}

part of DartCLibC;

class va_list {
  List arguments;
  int position;

  void initialize(List args, int pos) {
    arguments = args;
    position = pos;
  }

  Object next() {
    return arguments[position++].pointer();
  }
}

void __builtin_va_start(va_list ap, List args) {
  ap.initialize(args, 0);
}

dynamic __builtin_va_arg(va_list ap) {
  return ap.next();
}

void __builtin_va_copy(va_list dest, va_list src) {
  dest.initialize(src.arguments, src.position);
}

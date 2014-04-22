/**
 * Abstract superclass to be used in simulating variadic functions.
 * 
 * To simulate a variadic function subclass and override [body].
 */ 
abstract class C__VARARGS_FUNCTION {
  // Override in subclass to provide the function body.
  dynamic body(List arguments);
  
  // Redirect message, exposing (positional) arguments.
  dynamic noSuchMethod(Invocation invocation) {
    return body(invocation.positionalArguments);
  }
}

class va_list {
  List _arguments;
  int _position;
  
  void initialize(List arguments, int position) {
    _arguments = arguments;
    _position = position;
  }
  
  Object next() {
    ++_position;
    return _arguments[_position - 1];
  }
}

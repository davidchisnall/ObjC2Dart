int testAssignLiteral1() {
	int a;
	a = 1;
	return a;
}

int testAssignLiteral2() {
	int a = 2;
	return a;
}

int testAssignVariable() {
  int a = 3;
  int b = a;
  return b;
}

int testReturnLiteral() {
	return 4;
}

int testReturnVariable() {
	int a;
	// Should return the return value of the assignment, which is the value of a.
	return a = 5;
}

int testMultipleAssign() {
	int a = 5;
	a = 6;
	return a;
}

int main() {
  return 0;
}

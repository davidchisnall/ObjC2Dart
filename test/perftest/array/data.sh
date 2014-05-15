#!/bin/bash

# Usage: data.sh <start> <end> <step>

# Transpile test program
/Users/vlad/clang-llvm/xcode-build/Debug/bin/clang -cc1 -load /Users/vlad/clang-llvm/xcode-build/Debug/lib/libobjc2dart.dylib -plugin objc2dart -I/Users/vlad/Work/objc2dart/c/libc/ test.m > test.dart

for ((i = $1;  i <= $2; i += $3)) do

	# Change n in all files
	sed -e s/_N_/$i/g run_c.m > run_c.n.m
	sed -e s/_N_/$i/g run_dart.dart > run_dart.n.dart

	# Compile C
	clang -O0 test.m run_c.n.m -o run_c

	C_TIME="$(./run_c 2>&1)"
	DART_TIME="$(dart run_dart.n.dart 2>&1)"

	echo $C_TIME $DART_TIME

	rm run_c.n.m run_dart.n.dart

done

#!/bin/bash

# Usage: data.sh <test-name> <start> <end> <step>

# Transpile test program
/Users/vlad/clang-llvm/xcode-build/Debug/bin/clang -cc1 -load /Users/vlad/clang-llvm/xcode-build/Debug/lib/libobjc2dart.dylib -plugin objc2dart -I/Users/vlad/Work/objc2dart/c/libc/ $1.m > $1.dart

for ((i = $2;  i <= $3; i += $4)) do

	# Change n in all files
	sed -e s/_N_/$i/g run_c.m > run_c.n.m
	sed -e s/_N_/$i/g run_dart.dart > run_dart.n.dart
	sed -e s/_N_/$i/g run_dart-hand.dart > run_dart-hand.n.dart

	# Compile C
	clang -O0 $1.m run_c.n.m -o run_c

	C_TIME="$(./run_c 2>&1)"
	DART_TIME="$(dart run_dart.n.dart 2>&1)"
	DART_HAND_TIME="$(dart run_dart-hand.n.dart 2>&1)"

	echo $C_TIME $DART_HAND_TIME $DART_TIME

	rm run_c.n.m run_dart.n.dart run_dart-hand.n.dart

done

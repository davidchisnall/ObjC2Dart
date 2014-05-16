#!/bin/bash

# Usage: data.sh <test> <start> <end> <step>

pushd $1

# Transpile test program
/Users/vlad/clang-llvm/xcode-build/Debug/bin/clang -cc1 -load /Users/vlad/clang-llvm/xcode-build/Debug/lib/libobjc2dart.dylib -plugin objc2dart -I/Users/vlad/Work/objc2dart/c/libc/ test.m > test.dart

echo "# start $2 end $3 step $4" > data.txt

for ((i = $2;  i <= $3; i += $4)) do

# Change n in all files
sed -e s/_N_/$i/g run_c.m > run_c.n.m
sed -e s/_N_/$i/g run_dart.dart > run_dart.n.dart

# Compile C
clang -framework Foundation -O0 test.m run_c.n.m -o run_c

C_TIME="$(./run_c 2>&1)"
DART_TIME="$(dart run_dart.n.dart 2>&1)"

echo $C_TIME $DART_TIME >> data.txt

rm run_c.n.m run_dart.n.dart

done

popd

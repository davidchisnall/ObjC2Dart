#!/bin/bash

# Usage: data.sh <test-name> <n>

# Change n in all files

clang -O0 $1.m run_c.m -o run_c

C_TIME="$(./run_c 2>&1)"
DART_TIME="$(dart run_dart.dart 2>&1)"
DART_HAND_TIME="$(dart run_dart-hand.dart 2>&1)"

echo $C_TIME $DART_TIME $DART_HAND_TIME

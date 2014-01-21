# objc2dart

A tool to convert Objective-C programs to Dart.

# Building it

objc2dart is a Clang plugin. Currently this means that you need to check out Clang and build objc2dart inside its tree.

To set up the build for the command line:

1. Follow step 0 of [this tutorial](http://clang.llvm.org/docs/LibASTMatchersTutorial.html) to get and build Clang.
2. Symlink objc2dart in the Clang tools directory: `ln -s <objc2dart>/src <clang-llvm>/llvm/tools/clang/tools/extra/`.
3. Add `add_subdirectory(objc2dart)` to `<clang-llvm>/llvm/tools/clang/tools/extra/CMakeLists.txt`.
4. Run `ninja` in `<clang-llvm>/build`.
5. Add `export OBJC2DART_BUILD=<clang-llvm>/build` to your .bash_profile and source.

To recompile just run `ninja` in `<clang-llvm>/build`.

If you want to generate an Xcode project:

1. In your clang-llvm directory, make a directory for the Xcode project, say `mkdir xcode-build && cd xcode-build`
2. `cmake -G Xcode ../llvm`
5. Adjust .bash_profile to `export OBJC2DART_BUILD=<clang-llvm>/xcode-build/Debug` and source.
4. Enjoy Xcode

# Unit testing it

1. In your objc2dart directory, `mkdir test-bin && mkdir test-bin/unittest && cd test-bin/unittest`
2. `cmake -G Ninja ../../test/unittest`

Whenever you want to test:
1. Make sure that objc2dart is up to date - testing will not build it
2. Build the tests and run them with `ninja && ctest`

# Using it

Run `$OBJC2DART_BUILD/bin/clang -cc1 -load $OBJC2DART_BUILD/lib/libobjc2dart.dylib -plugin objc2dart <source-file>`.

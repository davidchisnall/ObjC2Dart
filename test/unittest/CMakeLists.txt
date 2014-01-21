cmake_minimum_required (VERSION 2.8)

# Project configuration
project (ObjC2Dart_UnitTests)

# Set ObjC2Dart as the compiler for .m files, which apparently are C++
# FIXME: only works with 1 source per target
set(CMAKE_CXX_COMPILE_OBJECT
	"$ENV{OBJC2DART_BUILD}/bin/clang -cc1 -load $ENV{OBJC2DART_BUILD}/lib/libobjc2dart.dylib -plugin objc2dart <SOURCE> > <OBJECT>")
set(CMAKE_CXX_LINK_EXECUTABLE "mv <OBJECTS> <TARGET>")

# Compile macro
macro (objc2dart name)
	add_executable(${name}.dart ${name}.m)
endmacro (objc2dart)

# Diff test macro
macro (add_diff_test name)
	configure_file(${name}.ref.dart ${name}.ref.dart COPYONLY)
	add_test(${name}_diff diff ${name}.dart ${name}.ref.dart)
endmacro (add_diff_test)

# Enable testing
enable_testing()

# Add tests
add_subdirectory(functions)

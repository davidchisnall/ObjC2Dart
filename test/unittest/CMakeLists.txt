cmake_minimum_required (VERSION 2.8)

# Project configuration
project (ObjC2Dart_UnitTests)

# Set ObjC2Dart as the compiler for .m files, which apparently are C++
# FIXME: only works with 1 source per target
set(CMAKE_CXX_COMPILE_OBJECT
	"$ENV{OBJC2DART_BUILD}/bin/clang -cc1 -load $ENV{OBJC2DART_BUILD}/lib/libobjc2dart.dylib -plugin objc2dart -I/Users/vlad/Work/objc2dart/c/libc/ <SOURCE> > <OBJECT>")
set(CMAKE_CXX_LINK_EXECUTABLE "mv <OBJECTS> <TARGET>")

# Compile macro
macro (objc2dart name)
	add_executable(${name}.dart ${name}.m)
endmacro (objc2dart)

# Diff test macro
macro (add_diff_test name)
	configure_file(${name}.ref.dart ${name}.ref.dart COPYONLY)
	add_test(${name}_diff diff ${name}.dart ${name}.ref.dart)
	add_test(${name}_run dart ${name}.dart)
endmacro (add_diff_test)

# Dart unit test macro
macro (add_dart_test name)
	configure_file(${name}.test.dart ${name}.test.dart COPYONLY)
	add_test(${name}_dart dart ${name}.test.dart)
	add_test(${name}_run dart ${name}.dart)
endmacro (add_dart_test)

# Packages symlink
file(COPY Packages DESTINATION .)

# Enable testing
enable_testing()

# Add tests
add_subdirectory(c)
add_subdirectory(libc)

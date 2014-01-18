set(SHARED_LIBRARY true)
set(LLVM_USED_LIBS clangTooling)

add_clang_library(objc2dart ObjC2Dart.cpp)

target_link_libraries(objc2dart
  clangTooling
  clangBasic
  clangASTMatchers
  )

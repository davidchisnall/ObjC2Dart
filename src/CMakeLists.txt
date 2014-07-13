cmake_minimum_required(VERSION 2.8.8)

find_package(LLVM)

# Define add_llvm_* macro's.
include(HandleLLVMOptions)
include(AddLLVM)

message("LLVM on UNIX? ${LLVM_ON_UNIX}")
message("Plugins? ${LLVM_ENABLE_PLUGINS}")

add_definitions(${LLVM_DEFINITIONS})
include_directories(${LLVM_INCLUDE_DIRS})
link_directories(${LLVM_LIBRARY_DIRS})


set(LLVM_LIBRARY_OUTPUT_INTDIR ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CFG_INTDIR}/lib)
set(LLVM_RUNTIME_OUTPUT_INTDIR ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CFG_INTDIR}/bin)

add_llvm_loadable_module(objc2dart ObjC2Dart.cpp)

target_link_libraries(objc2dart
  clangTooling
  clangBasic
  clangASTMatchers
  )


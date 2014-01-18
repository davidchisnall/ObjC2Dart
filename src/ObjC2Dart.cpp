//===- ObjC2Dart.cpp ------------------------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// A tool to convert an Objective-C compilation unit to Dart.
//
//===----------------------------------------------------------------------===//

#include "clang/Frontend/FrontendPluginRegistry.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/AST.h"
#include "clang/Frontend/CompilerInstance.h"
#include "llvm/Support/raw_ostream.h"

using namespace clang;

namespace {

  class DartWriterConsumer : public ASTConsumer {
  };

  class DartWriterAction : public PluginASTAction {
  protected:
    ASTConsumer *CreateASTConsumer(CompilerInstance &CI, llvm::StringRef) {
      return new DartWriterConsumer();
    }

    bool ParseArgs(const CompilerInstance &CI,
                   const std::vector<std::string>& args) {
      return true;
    }
    void PrintHelp(llvm::raw_ostream& ros) {
      ros << "Usage: \n";
    }
    
  };
  
}

static FrontendPluginRegistry::Add<DartWriterAction>
X("objc2dart", "Writes the compilation unit out to stdout as Dart code");

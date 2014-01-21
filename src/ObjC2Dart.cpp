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

#include "clang/AST/AST.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendPluginRegistry.h"
#include "llvm/Support/raw_ostream.h"

#include <unistd.h>

using namespace clang;

namespace {

// STDOUT output stream with nicer interface for indentation.
class IndentedOutputStream : public llvm::raw_fd_ostream {
  // The width in spaces of an indentation level.
  static const int LEVEL_WIDTH = 2;
  int level;

public:
  typedef llvm::raw_fd_ostream super;

  IndentedOutputStream() :
      llvm::raw_fd_ostream(STDOUT_FILENO, false, true), level(0) {}

  // Increases the indentation level by delta.
  IndentedOutputStream & increaseIndentationLevel(int delta = 1) {
    level += delta;
    return *this;
  }

  // Decreases the indentation level by delta.
  IndentedOutputStream & decreaseIndentationLevel(int delta = 1) {
    level -= delta;
    return *this;
  }

  // Inserts indentation at the cursor.
  llvm::raw_ostream & indent() {
    return super::indent(level * LEVEL_WIDTH);
  }
};

class DartWriter : public RecursiveASTVisitor<DartWriter> {
  // The output stream to which to write the Dart code.
  IndentedOutputStream OS;

  std::string DartTypeAsStringForQualType(const QualType &qualType) {
    // TODO
    return "int";
  }

public:
  DartWriter() : RecursiveASTVisitor<DartWriter>(), OS() {}

  // TODO: make sure any name ok in C is ok in Dart
  // TODO: varargs
  // TODO: investigate static functions
  bool TraverseFunctionDecl(FunctionDecl *d) {
    if (!d->getBody()) {
      // Just a function declaration.
      return true;
    }
    // Emit function declaration.
    // The main function in Dart returns void, not int so it needs wrapping.
    if (d->isMain()) {
      OS << "void main() {\n";
      OS.increaseIndentationLevel().indent();
    }
    OS << DartTypeAsStringForQualType(d->getResultType()) << " " <<
        d->getNameAsString() << "(";
    // Emit parameter list.
    for (FunctionDecl::param_iterator it = d->param_begin(),
         end = d->param_end(); it != end; ++it) {
      OS << (*it)->getNameAsString();
      if (it + 1 != end) {
        OS << ", ";
      }
    }
    OS << ") ";
    if (!TraverseStmt(d->getBody())) {
      return false;
    }
    if (d->isMain()) {
      OS << d->getNameAsString() << "();\n";
      OS.decreaseIndentationLevel().indent() << "}\n";
      OS.indent();
    }
    return true;
  }

  bool TraverseCompoundStmt(CompoundStmt *s) {
    OS << "{\n";
    OS.increaseIndentationLevel();
    for (CompoundStmt::body_iterator it = s->body_begin(), end = s->body_end();
         it != end; ++it) {
      OS.indent();
      if (!TraverseStmt(*it)) {
        return false;
      }
      OS << ";\n";
    }
    OS.decreaseIndentationLevel().indent() << "}\n";
    OS.indent();
    return true;
  }

  bool TraverseReturnStmt(ReturnStmt *s) {
    OS << "return ";
    return TraverseStmt(s->getRetValue());
  }

  bool VisitIntegerLiteral(IntegerLiteral *il) {
    OS << il->getValue();
    return true;
  }
};

class DartWriterConsumer : public ASTConsumer {
public:
  virtual void HandleTranslationUnit(ASTContext &ctx) {
    DartWriter dartWriter;
    dartWriter.TraverseDecl(ctx.getTranslationUnitDecl());
  }
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

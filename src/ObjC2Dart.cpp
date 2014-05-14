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

class CerrOutputStream : public llvm::raw_fd_ostream {
public:
  CerrOutputStream() : llvm::raw_fd_ostream(STDERR_FILENO, false, true) {}
};

class DartWriter : public RecursiveASTVisitor<DartWriter> {
  // The output stream to which to write the Dart code.
  IndentedOutputStream OS;
  CerrOutputStream cerr;

public:
  DartWriter() : RecursiveASTVisitor<DartWriter>(), OS(), cerr() {
    EmitDefaultImports();
  }

#pragma mark Imports

  void EmitDefaultImports() {
    // C types.
    OS << "import 'package:this/c/types.dart';\n";
  }

#pragma mark Declarations

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
    TraverseType(d->getResultType());
    OS << " " << d->getNameAsString() << "(";
    // Emit parameter list.
    for (FunctionDecl::param_iterator it = d->param_begin(),
         end = d->param_end(); it != end; ++it) {
      if (!TraverseDecl(*it)) {
        return false;
      }
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

  bool TraverseParmVarDecl(ParmVarDecl *d) {
    bool savedSupressVarDeclInitialisation = supressVarDeclInitialisation;
    supressVarDeclInitialisation = true;
    bool success = TraverseVarDecl(d);
    supressVarDeclInitialisation = savedSupressVarDeclInitialisation;
    return success;
  }

  bool supressVarDeclType = false;
  bool supressVarDeclInitialisation = false;

  bool TraverseVarDecl(VarDecl *d) {
    if (supressVarDeclType || TraverseType(d->getType())) {
      OS << " " << d->getNameAsString();
      if (!supressVarDeclInitialisation && !TypeIsDartClass(d->getType())) {
        if (d->hasInit()) {
          OS << " = ";
          if (!TraverseStmt(d->getInit())) {
            return false;
          }
        } else {
          OS << " = new ";
          if (!TraverseType(d->getType())) {
            return false;
          }
          OS << ".local()";
        }
      }
      return true;
    } else {
      return false;
    }
  }

  bool TraverseTypedefDecl(TypedefDecl *d) {
    return true;
  }

  bool TraverseDeclStmt(DeclStmt *d) {
    bool first = true;
    bool savedSupressVarDeclType = supressVarDeclType;
    for (DeclStmt::decl_iterator i = d->decl_begin(); i != d->decl_end(); ++i) {
      if (first) {
        first = false;
      } else {
        OS << ", ";
        supressVarDeclType = true;
      }
      if (!TraverseDecl(*i)) {
        supressVarDeclType = savedSupressVarDeclType;
        return false;
      }
    }
    supressVarDeclType = savedSupressVarDeclType;
    return true;
  }

#pragma mark Statements

  bool TraverseStmt(Stmt *s) {
    if (!s) {
      return true;
    } else if (s->getStmtClass() == Stmt::BinaryOperatorClass) {
      return TraverseBinaryOperator(static_cast<BinaryOperator *>(s));
    } else {
      return RecursiveASTVisitor::TraverseStmt(s);
    }
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

  bool TraverseIfStmt(IfStmt *s) {
    OS << "if (";
    if (!TraverseStmt(s->getCond())) {
      return false;
    }
    OS << ") ";
    if (!TraverseStmt(s->getThen())) {
      return false;
    }
    OS << " else ";
    return TraverseStmt(s->getElse());
  }

  bool TraverseDoStmt(DoStmt *s) {
    OS << "do ";
    if (!TraverseStmt(s->getBody())) {
      return false;
    }
    OS << "while (";
    if (!TraverseStmt(s->getCond())) {
      return false;
    }
    OS << ")";
    return true;
  }

#pragma mark Expressions

  bool TraverseCallExpr(CallExpr *e) {
    if (!TraverseStmt(e->getCallee())) {
      return false;
    }
    OS << "(";
    for (CallExpr::arg_iterator it = e->arg_begin(), end = e->arg_end();
         it != end; ++it) {
      if (!TraverseStmt(*it)) {
        return false;
      }
      if (it + 1 != end) {
        OS << ", ";
      }
    }
    OS << ")";
    return true;
  }

  bool TraverseDeclRefExpr(DeclRefExpr *e) {
    OS << e->getDecl()->getNameAsString();
    return true;
  }

  bool TraverseBinaryOperator(BinaryOperator *o) {
    if (o->getOpcode() == BO_Comma) {
      // There can be no definitions in it, so wrap it in a closure.
      OS << "(){ ";
      if (!TraverseStmt(o->getLHS())) {
        return false;
      }
      OS << "; return ";
      if (!TraverseStmt(o->getRHS())) {
        return false;
      }
      OS << "; }()";
      return true;
    } else if (o->getOpcode() == BO_Assign) {
      if (!TraverseStmt(o->getLHS())) {
        return false;
      }
      OS << ".set(";
      if (!TraverseStmt(o->getRHS())) {
        return false;
      }
      OS << ")";
      return true;
    } else {
      if (!TraverseStmt(o->getLHS())) {
        return false;
      }
      OS << " " << o->getOpcodeStr(o->getOpcode()) << " ";
      return TraverseStmt(o->getRHS());
    }
  }

  bool TraverseUnaryOperator(UnaryOperator *o) {
    OS << o->getOpcodeStr(o->getOpcode()) << " ";
    return TraverseStmt(o->getSubExpr());
  }

  bool TraverseUnaryExprOrTypeTraitExpr(UnaryExprOrTypeTraitExpr *e) {
    // Everything is 64 bits.
    OS << "(new C__TYPE_Int64.literal(8))";
    return true;
  }

#pragma mark Types

  bool TraverseConstantArrayType(ArrayType *t) {
    return TraverseArrayType(t);
  }

  bool TraverseVariableArrayType(ArrayType *t) {
    return TraverseArrayType(t);
  }

  bool TraverseIncompleteArrayType(ArrayType *t) {
    return TraverseArrayType(t);
  }

  bool TraverseArrayType(ArrayType *t) {
    OS << "C__TYPE_Pointer";
    return true;
  }

  bool TraversePointerType(PointerType *t) {
    OS << "C__TYPE_Pointer";
    return true;
  }

  bool TraverseBuiltinType(BuiltinType *t) {
    if (t->isVoidType()) {
      OS << "void";
    } else if (t->isSignedInteger() || t->isUnsignedInteger()) {
      OS << "C__TYPE_Int64";
    }
    return true;
  }

  const std::string dartClassName = "__objc2dart__dart_class";

  bool TraverseTypedefType(TypedefType *t) {
    QualType source = t->getDecl()->getTypeSourceInfo()->getType();
    // Stop following the typedef chain before dartClassName.
    if (t->getDecl()->getNameAsString() == dartClassName) {
      OS << "var";
    } else if (source.getAsString() == dartClassName) {
      OS << t->getDecl()->getNameAsString();
    } else {
      return TraverseType(source);
    }
    return true;
  }

  bool TypeIsDartClass(QualType qt) {
    const Type *t = qt.getTypePtr();
    if (t->getTypeClass() == Type::Typedef) {
      const TypedefType *tt = static_cast<const TypedefType *>(t);
      QualType source = tt->getDecl()->getTypeSourceInfo()->getType();
      // Stop following the typedef chain before dartClassName.
      if (tt->getDecl()->getNameAsString() == dartClassName ||
          source.getAsString() == dartClassName) {
        return true;
      } else {
        return TypeIsDartClass(source);
      }
    } else {
      return false;
    }
  }

#pragma mark Return

  bool TraverseReturnStmt(ReturnStmt *s) {
    OS << "return ";
    return TraverseStmt(s->getRetValue());
  }

#pragma mark Literals

  bool VisitIntegerLiteral(IntegerLiteral *il) {
    OS << "(new C__TYPE_Int64.literal(" << il->getValue() << "))";
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

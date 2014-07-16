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
    // Stdlib.
    OS << "import 'package:this/libc/stdlib.dart';\n";
    // Varargs.
    OS << "import 'package:this/libc/stdarg.dart';\n";
    // NSObject.
    OS << "import 'package:this/objc/NSObject.dart';\n";
    OS << "\n";
  }

#pragma mark Declarations

  FunctionDecl *currentFunctionDecl = NULL;

  // TODO: make sure any name ok in C is ok in Dart
  // TODO: varargs
  // TODO: investigate static functions
  bool TraverseFunctionDecl(FunctionDecl *d) {
    if (!d->getBody()) {
      // Just a function declaration.
      return true;
    }
    FunctionDecl *savedCurrentFunctionDecl = currentFunctionDecl;
    currentFunctionDecl = d;
    // Emit function declaration.
    // The main function in Dart returns void, not int so it needs wrapping.
    if (d->isMain()) {
      OS << "void main() {\n";
      OS.increaseIndentationLevel().indent();
    } else if (d->isVariadic()) {
      OS << "class C__VARARGS_FUNCTION_" << d->getNameAsString() <<
          " extends C__VARARGS_FUNCTION {\n";
      OS.increaseIndentationLevel().indent();
      OS << "dynamic body(List arguments) {\n";
      OS.increaseIndentationLevel().indent();
      int argn = 0;
      for (FunctionDecl::param_iterator it = d->param_begin(),
           end = d->param_end(); it != end; ++it) {
        if (!TraverseDecl(*it)) {
          return false;
        }
        OS << " = arguments[" << argn << "];\n";
        ++argn;
        OS.indent();
      }
    } else {
      TraverseType(d->getReturnType());
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
    }
    if (!TraverseStmt(d->getBody())) {
      return false;
    }
    if (d->isMain()) {
      OS << d->getNameAsString() << "();\n";
      OS.decreaseIndentationLevel().indent() << "}\n";
      OS.indent();
    } else if (d->isVariadic()) {
      OS << "}\n";
      OS.decreaseIndentationLevel().indent();
      OS << "}\n";
      OS.decreaseIndentationLevel().indent();
      OS << "Object " << d->getNameAsString() << " = new C__VARARGS_FUNCTION_" << d->getNameAsString()
          << "();\n";
      OS.indent();
    }
    currentFunctionDecl = savedCurrentFunctionDecl;
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
      if (!supressVarDeclInitialisation) {
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
          if (TypeIsDartClass(d->getType())) {
            OS << "()";
          } else {
            if (((d->getType()).getTypePtr())->isPointerType()) {
              OS << ".local(C__TYPE_DEFINITION.int64_t)";
            } else {
              OS << ".local()";
            }
          }
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

  bool TraverseObjCImplementationDecl(ObjCImplementationDecl *d) {
    OS << "class " << d->getNameAsString() << " extends NSObject {\n";
    OS.increaseIndentationLevel().indent();
    for (ObjCContainerDecl::method_iterator it = d->meth_begin(),
         end = d->meth_end(); it != end; ++it) {
      TraverseDecl(*it);
    }
    OS << "}\n";
    OS.decreaseIndentationLevel().indent();
    return true;
  }

  bool TraverseObjCMethodDecl(ObjCMethodDecl *d) {
    TraverseType(d->getReturnType());
    OS << " " << d->getNameAsString() << "(";
    for (ObjCMethodDecl::param_iterator it = d->param_begin(),
         end = d->param_end(); it != end; ++it) {
      if (it != d->param_begin()) {
        OS << ", ";
      }
      TraverseDecl(*it);
    }
    OS << ") ";
    TraverseStmt(d->getBody());
    return true;
  }

#pragma mark Statements

  bool TraverseStmt(Stmt *s) {
    if (!s) {
      return true;
    } else if (s->getStmtClass() == Stmt::BinaryOperatorClass) {
      return TraverseBinaryOperator(static_cast<BinaryOperator *>(s));
    } else if (s->getStmtClass() == Stmt::UnaryOperatorClass) {
      return TraverseUnaryOperator(static_cast<UnaryOperator *>(s));
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

  bool TraverseForStmt(ForStmt *s) {
    OS << "for (";
    if (!TraverseStmt(s->getInit())) {
      return false;
    }
    OS << "; ";
    if (!TraverseStmt(s->getCond())) {
      return false;
    }
    OS << "; ";
    if (!TraverseStmt(s->getInc())) {
      return false;
    }
    OS << ") ";
    return TraverseStmt(s->getBody());
  }

#pragma mark Expressions

  bool check_va_start_on = false;
  bool check_va_start_return = false;
  std::string check_va_start_argname;

  bool TraverseCallExpr(CallExpr *e) {
    if (!TraverseStmt(e->getCallee())) {
      return false;
    }
    check_va_start_on = true;
    check_va_start_return = false;
    TraverseStmt(e->getCallee());
    check_va_start_on = false;
    OS << "(";
    if (!check_va_start_return) {
      for (CallExpr::arg_iterator it = e->arg_begin(), end = e->arg_end();
           it != end; ++it) {
        if (!TraverseStmt(*it)) {
          return false;
        }
        if (it + 1 != end) {
          OS << ", ";
        }
      }
    } else {
      if (!TraverseStmt(*(e->arg_begin()))) {
        return false;
      }
      OS << ", ";
      check_va_start_on = true;
      TraverseStmt(*(e->arg_begin() + 1));
      check_va_start_on = false;
      int argn = 0;
      for (FunctionDecl::param_iterator it = currentFunctionDecl->param_begin(),
           end = currentFunctionDecl->param_end(); it != end; ++it) {
        VarDecl *d = static_cast<VarDecl *>(*it);
        if ((d->getNameAsString()).compare(check_va_start_argname) == 0) {
          OS << argn + 1 << ", arguments";
          break;
        }
        ++argn;
      }
    }
    OS << ")";
    return true;
  }

  bool TraverseDeclRefExpr(DeclRefExpr *e) {
    if (check_va_start_on) {
      check_va_start_argname = e->getDecl()->getNameAsString();
      if (check_va_start_argname.compare("va_start") == 0) {
        check_va_start_return = true;
      }
    } else {
      OS << e->getDecl()->getNameAsString();
    }
    return true;
  }


  bool emitSimpleBinOp(Expr *LHS, Expr *RHS, const char *OpStr, bool Assign) {
    bool ret;
    if (Assign) {
      OS << "() { var __tmp = ";
      ret = TraverseStmt(LHS);
      OS << "; __tmp";
    } else
      ret = TraverseStmt(LHS);
    OS << OpStr << '(';
    ret &= TraverseStmt(RHS);
    OS << ')';
    if (Assign)
      OS << "; }()";
    return ret;
  }

  bool TraverseBinMulAssign(CompoundAssignOperator *O) {
    return TraverseBinaryOperator(O);
  }
  bool TraverseBinDivAssign(CompoundAssignOperator *O) {
    return TraverseBinaryOperator(O);
  }
  bool TraverseBinRemAssign(CompoundAssignOperator *O) {
    return TraverseBinaryOperator(O);
  }
  bool TraverseBinAddAssign(CompoundAssignOperator *O) {
    return TraverseBinaryOperator(O);
  }
  bool TraverseBinSubAssign(CompoundAssignOperator *O) {
    return TraverseBinaryOperator(O);
  }
  bool TraverseBinXorAssign(CompoundAssignOperator *O) {
    return TraverseBinaryOperator(O);
  }
  bool TraverseBinOrAssign(CompoundAssignOperator *O) {
    return TraverseBinaryOperator(O);
  }

  bool TraverseBinaryOperator(BinaryOperator *O) {
    Expr *LHS = O->getLHS(), *RHS = O->getRHS();
    BinaryOperator::Opcode Opc = O->getOpcode();
    bool IsAssign = false;
    switch (Opc) {
      case BO_Comma: {
        // There can be no definitions in it, so wrap it in a closure.
        OS << "(){ ";
        if (!TraverseStmt(LHS))
          return false;
        OS << "; return ";
        if (!TraverseStmt(RHS))
          return false;
        OS << "; }()";
        return true;
      }
      case BO_Assign:
        return emitSimpleBinOp(LHS, RHS, ".set", IsAssign);
        IsAssign = true;
      case BO_MulAssign: case BO_DivAssign: case BO_RemAssign:
      case BO_AddAssign: case BO_SubAssign: case BO_AndAssign:
      case BO_XorAssign: case BO_OrAssign: case BO_ShrAssign:
      case BO_ShlAssign:
        IsAssign = true;
      // These operators are the same in dart and C:
      case BO_And: case BO_Xor: case BO_Or: case BO_LAnd: case BO_LOr:
      case BO_Mul: case BO_Div: case BO_Rem: case BO_Add: case BO_Sub:
      case BO_LT: case BO_GT: case BO_LE: case BO_GE: case BO_EQ: case BO_NE:
      case BO_Shl: case BO_Shr:
        return emitSimpleBinOp(LHS, RHS,
          BinaryOperator::getOpcodeStr(Opc).str().c_str(), IsAssign);
      // C++ operators, not supported
      case BO_PtrMemD: case BO_PtrMemI:
        return false;
    }
  }

  bool TraverseUnaryOperator(UnaryOperator *o) {
    if (o->getOpcodeStr(o->getOpcode()).compare("*") == 0) {
      if (!TraverseStmt(o->getSubExpr())) {
        return false;
      }
      OS << ".pointee";
      return true;
    } else if (o->getOpcodeStr(o->getOpcode()).compare("&") == 0) {
      if (!TraverseStmt(o->getSubExpr())) {
        return false;
      }
      OS << ".pointer()";
      return true;
    } else if (o->getOpcodeStr(o->getOpcode()).compare("++") == 0) {
      if (!TraverseStmt(o->getSubExpr())) {
        return false;
      }
      OS << ".inc()";
      return true;
    } else {
      OS << o->getOpcodeStr(o->getOpcode()) << " ";
      return TraverseStmt(o->getSubExpr());
    }
  }

  bool TraverseUnaryExprOrTypeTraitExpr(UnaryExprOrTypeTraitExpr *e) {
    // Everything is 64 bits.
    OS << "(new C__TYPE_Int64.literal(8))";
    return true;
  }

  bool TraverseArraySubscriptExpr(ArraySubscriptExpr *e) {
    TraverseStmt(e->getLHS());
    OS << ".index(";
    TraverseStmt(e->getRHS());
    OS << ")";
    return true;
  }

  bool TraverseObjCMessageExpr(ObjCMessageExpr *e) {
//    OS << "(";
    if (e->isInstanceMessage()) {
      OS << e->getReceiverInterface()->getNameAsString();
      TraverseStmt(e->getInstanceReceiver());
    } else {
      TraverseType(e->getClassReceiver());
    }
    OS << "." << (e->getSelector()).getAsString() << "()";
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

  bool TraverseObjCObjectPointerType(ObjCObjectPointerType *t) {
    OS << t->getInterfaceDecl()->getNameAsString() << " ";
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

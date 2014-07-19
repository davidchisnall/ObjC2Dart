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

#include "clang/Basic/Builtins.h"
#include "clang/AST/AST.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/AST/RecordLayout.h"
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

  const char *DartCClassForCBuiltin(QualType Ty) {
    Ty = Ty.getCanonicalType();
    const BuiltinType *BT = cast<BuiltinType>(Ty.getTypePtr());
    return DartCClassForCBuiltin(BT);
  }
  const char *DartCClassForCBuiltin(const BuiltinType *BT) {
    switch (BT->getKind()) {
      case BuiltinType::Bool:
      case BuiltinType::Char_U:
      case BuiltinType::UChar:
        return "DartCUnsignedChar";
      case BuiltinType::SChar:
      case BuiltinType::Char_S:
        return "DartCSignedChar";
      case BuiltinType::Short:
        return "DartCSignedShort";
      case BuiltinType::UShort:
        return "DartCUnsignedShort";
      case BuiltinType::Int:
        return "DartCSignedInt";
      case BuiltinType::UInt:
        return "DartCUnsignedInt";
      case BuiltinType::Long:
      case BuiltinType::LongLong:
        return "DartCSignedLong";
      case BuiltinType::ULong:
      case BuiltinType::ULongLong:
        return "DartCUnsignedLong";
      case BuiltinType::Float:
        return "DartCFloat";
      case BuiltinType::Double:
        return "DartCDouble";
      default:
        BT->dump();
        abort();
    }
  }
  const char *DartCMethodForCBuiltin(QualType Ty) {
    Ty = Ty.getCanonicalType();
    const BuiltinType *BT = cast<BuiltinType>(Ty.getTypePtr());
    return DartCMethodForCBuiltin(BT);
  }
  const char *DartCMethodForCBuiltin(const BuiltinType *BT) {
    switch (BT->getKind()) {
      case BuiltinType::Bool:
      case BuiltinType::Char_U:
      case BuiltinType::UChar:
        return "unsignedChar";
      case BuiltinType::SChar:
      case BuiltinType::Char_S:
        return "signedChar";
      case BuiltinType::Short:
        return "signedShort";
      case BuiltinType::UShort:
        return "unsignedShort";
      case BuiltinType::Int:
        return "signedInt";
      case BuiltinType::UInt:
        return "unsignedInt";
      case BuiltinType::Long:
      case BuiltinType::LongLong:
        return "signedLong";
      case BuiltinType::ULong:
      case BuiltinType::ULongLong:
        return "unsignedLong";
      case BuiltinType::Float:
        return "float";
      case BuiltinType::Double:
        return "double";
      default:
        BT->dump();
        abort();
    }
  }
  size_t SizeForCBuiltin(const BuiltinType *BT) {
    switch (BT->getKind()) {
      case BuiltinType::Bool:
      case BuiltinType::Char_U:
      case BuiltinType::UChar:
      case BuiltinType::SChar:
      case BuiltinType::Char_S:
        return 1;
      case BuiltinType::Short:
      case BuiltinType::UShort:
        return 2;
      case BuiltinType::Int:
      case BuiltinType::UInt:
      case BuiltinType::Float:
        return 4;
      case BuiltinType::Long:
      case BuiltinType::LongLong:
      case BuiltinType::ULong:
      case BuiltinType::ULongLong:
      case BuiltinType::Double:
        return 8;
      default:
        BT->dump();
        abort();
    }
  }
  struct TypeInfo
  {
    const char *DartCClass;
    const char *DartCMethod;
    int Size;
    bool IsBuiltin;
  };
  TypeInfo getTypeInfo(QualType Ty) {
    Ty = Ty.getCanonicalType();
    TypeInfo TI;
    if (const BuiltinType *BT = dyn_cast<BuiltinType>(Ty)) {
      TI.DartCClass = DartCClassForCBuiltin(BT);
      TI.DartCMethod = DartCMethodForCBuiltin(BT);
      TI.Size = SizeForCBuiltin(BT);
      TI.IsBuiltin = true;
    } else {
      assert(Ty->isRecordType());
      TI.DartCClass = "DartCComposite";
      TI.DartCMethod = "composite";
      const RecordDecl *RD = Ty->getAs<RecordType>()->getDecl();
      const ASTRecordLayout &RL = C.getASTRecordLayout(RD);
      TI.Size = RL.getSize().getQuantity();
      TI.IsBuiltin = false;
    }
    return TI;
  }
  ASTContext &C;
public:
  DartWriter(ASTContext &ctx) :
    RecursiveASTVisitor<DartWriter>(), OS(), cerr(), C(ctx) {
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
      if (d->isVariadic())
        OS << ", List __variadic_arguments";
      OS << ") ";
    }
    if (!TraverseStmt(d->getBody())) {
      return false;
    }
    if (d->isMain()) {
      OS << d->getNameAsString() << "();\n";
      OS.decreaseIndentationLevel().indent() << "}\n";
      OS.indent();
    }
    currentFunctionDecl = savedCurrentFunctionDecl;
    return true;
  }

  bool TraverseMemberExpr(MemberExpr *E) {
    Expr *Base = E->getBase();
    OS << '(';
    bool ret = TraverseStmt(Base);
    OS << ").";
    const RecordDecl *RD;
    if (E->isArrow()) {
      OS << "dereference().";
      QualType RecordTy =
        Base->getType()->getAs<PointerType>()->getPointeeType();
      RD = RecordTy.getCanonicalType()->getAs<RecordType>()->getDecl();
    } else {
      RD = Base->getType().getCanonicalType()->getAs<RecordType>()->getDecl();
    }
    FieldDecl *Field = cast<FieldDecl>(E->getMemberDecl());
    const ASTRecordLayout &RL = C.getASTRecordLayout(RD);
    int64_t Offset = RL.getFieldOffset(Field->getFieldIndex()) / 8;
    QualType FieldTy = E->getType().getCanonicalType();
    TypeInfo FieldInfo = getTypeInfo(FieldTy);
    OS << FieldInfo.DartCMethod << "AtOffset(" << Offset;
    if (!FieldInfo.IsBuiltin)
      OS << ", " << FieldInfo.Size;
    OS << ')';
    return ret;
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
          OS << "()";
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

  bool TraverseStmt(const Stmt *S) {
    return TraverseStmt(const_cast<Stmt*>(S));
  }
  bool TraverseStmt(Stmt *s) {
    if (!s)
      return true;
    // If this is an expression that we can statically evaluate, let's do that.
    if (Expr *E = dyn_cast<Expr>(s)) {
      llvm::APSInt Result;
      if (E->EvaluateAsInt(Result, C)) {
        OS << "(new " << DartCClassForCBuiltin(E->getType()) <<
          ".fromInt(" << Result << "))";
        return true;
      }
    }
    if (BinaryOperator *BO = dyn_cast<BinaryOperator>(s))
      return TraverseBinaryOperator(BO);
    if (UnaryOperator *UO = dyn_cast<UnaryOperator>(s))
      return TraverseUnaryOperator(UO);
    if (CastExpr *CE = dyn_cast<CastExpr>(s))
      return TraverseCastExpr(CE);
    return RecursiveASTVisitor::TraverseStmt(s);
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
    OS << "if ((";
    if (!TraverseStmt(s->getCond())) {
      return false;
    }
    OS << ").intValue() != 0) {\n";
    OS.increaseIndentationLevel().indent();
    if (!TraverseStmt(s->getThen())) {
      return false;
    }
    OS << ";\n";
    OS.decreaseIndentationLevel().indent();
    if (!s->getElse()) {
      OS << "}\n";
      return true;
    }
    OS << "} else {\n";
    OS.increaseIndentationLevel().indent();
    bool ret =  TraverseStmt(s->getElse());
    OS << ";\n";
    OS.decreaseIndentationLevel().indent();
    OS << "}\n";
    return ret;
  }

  bool TraverseWhileStmt(WhileStmt *S) {
    OS << "while ((";
    bool ret = TraverseStmt(S->getCond());
    OS << ").intValue() != 0)\n";
    OS.increaseIndentationLevel().indent();
    ret &= TraverseStmt(S->getBody());
    OS.decreaseIndentationLevel().indent();
    return ret;
  }

  bool TraverseDoStmt(DoStmt *s) {
    OS << "do ";
    if (!TraverseStmt(s->getBody())) {
      return false;
    }
    OS << "while ((";
    if (!TraverseStmt(s->getCond())) {
      return false;
    }
    OS << ").intValue() != 0)";
    return true;
  }

  bool TraverseForStmt(ForStmt *s) {
    OS << "for (";
    if (!TraverseStmt(s->getInit())) {
      return false;
    }
    OS << "; (";
    if (!TraverseStmt(s->getCond())) {
      return false;
    }
    OS << ").intValue() != 0 ; ";
    if (!TraverseStmt(s->getInc())) {
      return false;
    }
    OS << ") ";
    return TraverseStmt(s->getBody());
  }

  bool TraverseBreakStmt(BreakStmt *S) {
    OS << "break";
    return true;
  }
  bool TraverseContinueStmt(ContinueStmt *S) {
    OS << "continue";
    return true;
  }
  int SwitchLabels = 1;
  bool TraverseSwitchStmt(SwitchStmt *S) {
    OS << "switch (";
    bool Ret = TraverseStmt(S->getCond());
    OS << ".intValue()) {\n";
    OS.increaseIndentationLevel().indent();
    // If there's a default statement, then we must emit it last (Dart
    // requirement), so keep track of it and emit it at the end
    const DefaultStmt *Default = nullptr;
    int DefaultFallthroughTarget;
    llvm::SmallVector<const SwitchCase*, 8> Cases;
    for (SwitchCase *Case = S->getSwitchCaseList() ; Case ; Case =
        Case->getNextSwitchCase())
      Cases.push_back(Case);
    std::reverse(Cases.begin(), Cases.end());
    int Left = Cases.size();
    for (const SwitchCase *Case : Cases) {
      Left--;
      if (isa<DefaultStmt>(Case)) {
        Default = cast<DefaultStmt>(Case);
        Case = Case->getNextSwitchCase();
        DefaultFallthroughTarget = SwitchLabels;
        continue;
      }
      const CaseStmt *CS = cast<CaseStmt>(Case);
      llvm::APSInt Result;
      Ret = CS->getLHS()->EvaluateAsInt(Result, C);
      OS << "label" << SwitchLabels++ << ": case ";
      OS << Result << ":\n";
      OS.increaseIndentationLevel().indent();
      Ret &= TraverseStmt(CS->getSubStmt());
      OS << ";\n";
      OS.indent();
      if (Left)
        OS << "continue label" << SwitchLabels << ";\n";
      else
        OS << "break;\n";
      OS.decreaseIndentationLevel().indent();
    }
    if (SwitchLabels == DefaultFallthroughTarget)
      DefaultFallthroughTarget = 0;
    if (Default) {
      OS << "label" << SwitchLabels++ << ": default:\n";
      OS.increaseIndentationLevel().indent();
      Ret &= TraverseStmt(Default->getSubStmt());
      OS << ";\n";
      if (DefaultFallthroughTarget) {
        OS.indent();
        OS << "continue label" << DefaultFallthroughTarget << ";\n";
        OS.decreaseIndentationLevel().indent();
      }
    }
    OS << '\n';
    OS.decreaseIndentationLevel().indent();
    OS << '}';
    return Ret;
  }
  bool TraverseDefaultStmt(DefaultStmt *CS) {
    return true;
  }
  bool TraverseCaseStmt(CaseStmt *CS) {
    return true;
  }
#pragma mark Expressions

  bool TraverseVAArgExpr(VAArgExpr *E) {
    OS << "__builtin_va_arg(";
    bool ret = TraverseStmt(E->getSubExpr()->IgnoreParenCasts());
    OS << ')';
    return ret;
  }

  bool TraverseCallExpr(CallExpr *e) {
    if (int BI = e->getBuiltinCallee()) {
      if (BI == Builtin::BI__builtin_va_start) {
        OS << "__builtin_va_start(";
        int ret = TraverseStmt(e->getArg(0)->IgnoreParenCasts());
        OS << ", __variadic_arguments)";
        return ret;
      }
      if (BI == Builtin::BI__builtin_va_copy) {
        OS << "__builtin_va_copy(";
        int ret = TraverseStmt(e->getArg(0)->IgnoreParenCasts());
        OS << ", ";
        ret &= TraverseStmt(e->getArg(1)->IgnoreParenCasts());
        OS << ')';
        return ret;
      }
      // No cleanup needed for va_lists
      if (BI == Builtin::BI__builtin_va_end) {
        OS << "/* va_end */";
        return true;
      }
    }
    bool IsIndirect = false;;
    bool ret = true;
    if (FunctionDecl *FD = e->getDirectCallee()) {
      OS << FD->getNameAsString() << '(';
    } else {
      OS << "Function.apply((";
      ret = TraverseStmt(e->getCallee());
      OS << ").getFunction(), [";
      IsIndirect = true;
    }
    QualType CalleeTy = e->getCallee()->IgnoreParenCasts()->getType();
    if (const PointerType *PT = CalleeTy->getAs<PointerType>())
      CalleeTy = PT->getPointeeType();
    const FunctionProtoType *FT =
      CalleeTy->getAs<FunctionProtoType>();
    int NonVariadicArgs = INT_MAX;
    if (FT && FT->isVariadic())
      NonVariadicArgs = FT->getNumParams();
    for (CallExpr::arg_iterator it = e->arg_begin(), end = e->arg_end();
         it != end; ++it) {
      NonVariadicArgs--;
      OS << '(';
      ret &= TraverseStmt(*it);
      OS << ").copy()";
      if (it + 1 != end) {
        OS << ", ";
        if (NonVariadicArgs == 0)
          OS << "[ ";
      }
    }
    if (NonVariadicArgs <= 0)
      OS << ']';
    if (IsIndirect)
      OS << ']';
    OS << ")";
    return ret;
  }

  bool TraverseDeclRefExpr(DeclRefExpr *e) {
    OS << e->getDecl()->getNameAsString();
    return true;
  }

  /**
   * Emits a pointer cast.  Assuming that we've just emitted an expression that
   * evaluates to a pointer, cast the result to the correct kind of pointer.
   */
  void EmitPointerCastTo(QualType DstTy) {
    QualType ElementTy = DstTy->getAs<PointerType>()->getPointeeType();
    if (ElementTy->isVoidType()) {
      OS << ".unsignedCharPointerCast()";
      return;
    }
    TypeInfo TI = getTypeInfo(ElementTy);
    OS << '.' << TI.DartCMethod << "PointerCast(";
    if (!TI.IsBuiltin)
      OS << ", " << TI.Size;
    OS << ')';
  }

  bool TraverseCastExpr(CastExpr *E) {
    // We treat c-style casts, implicit casts, and so on as equivalent
    // We ignore the type of the C cast and only concern ourselves with whether
    // it involves something requiring explicit coercion in Dart.
    QualType DstTy = E->getType();
    bool ret = false;
    switch (E->getCastKind()) {
      default:
        llvm::errs() << "Unhandled cast kind: " << E->getCastKindName() << '\n';
        break;
      case CK_LValueToRValue:
      case CK_NoOp:
        ret = TraverseStmt(E->getSubExpr());
        break;
      case CK_FunctionToPointerDecay:
        OS << "(new DartCFunctionPointer.pointerTo(";
        ret = TraverseStmt(E->getSubExpr());
        OS << "))";
        break;
      // Cast types that produce arithmetic types
      case CK_IntegralCast:
      case CK_FloatingToIntegral:
      case CK_IntegralToFloating:
      case CK_PointerToIntegral:
      case CK_FloatingCast:
        OS << '(';
        ret = TraverseStmt(E->getSubExpr());
        OS << ")." << DartCMethodForCBuiltin(DstTy) << "Value()";
        break;
      case CK_IntegralToPointer:
        OS << '(';
        ret = TraverseStmt(E->getSubExpr());
        OS << ").pointerValue()";
        EmitPointerCastTo(DstTy);
        break;
      case CK_ArrayToPointerDecay: {
        QualType ElementTy =
          DstTy->getAs<PointerType>()->getPointeeType().getCanonicalType();
        OS << '(';
        ret = TraverseStmt(E->getSubExpr());
        OS << ").addressOf()";
        EmitPointerCastTo(DstTy);
        break;
      }
      case CK_ToUnion: {
        TypeInfo TI = getTypeInfo(DstTy);
        assert(TI.Size >= getTypeInfo(E->getSubExpr()->getType()).Size);
        OS << "(new DartComposite.alloc(" << TI.Size << ").set(";
        ret = TraverseStmt(E->getSubExpr());
        OS << "))";
        break;
      }
      case CK_BitCast:{
        QualType SrcTy = E->getSubExpr()->getType();
        // Currently, bitcasts are assumed to be pointer casts
        assert(DstTy->isPointerType());
        assert(SrcTy->isPointerType());
        OS << '(';
        ret = TraverseStmt(E->getSubExpr());
        OS << ')';
        EmitPointerCastTo(DstTy);
      }

    }
    return ret;
  }

  bool emitSimpleBinOp(Expr *LHS, Expr *RHS, const char *OpStr, bool Assign) {
    bool ret;
    const char *end = ")";
    // TODO: We could remove a lot of overhead on arithmetic if we were to
    // provide methods on DartCInteger for compound assignment
    if (Assign) {
      // If the LHS is just a variable reference, then we don't need to create
      // a closure to avoid double evaluation.  If it isn't, then we do.
      if (isa<DeclRefExpr>(LHS)) {
        ret = TraverseStmt(LHS);
        OS << ".set(";
        ret = TraverseStmt(LHS);
        Assign = false;
        end = "))";
      } else {
        OS << "() { var __tmp = ";
        ret = TraverseStmt(LHS);
        OS << "; __tmp";
        end = "; }()";
      }
    } else
      ret = TraverseStmt(LHS);
    OS << OpStr << '(';
    ret &= TraverseStmt(RHS);
    OS << end;
    return ret;
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
      case BO_EQ:
        return emitSimpleBinOp(LHS, RHS, ".eq", false);
      case BO_NE:
        return emitSimpleBinOp(LHS, RHS, ".ne", false);
      case BO_Assign:
        // This is an assignment, but it's not also an operation
        return emitSimpleBinOp(LHS, RHS, ".set", false);
      case BO_LAnd:
        return emitSimpleBinOp(LHS, RHS, ".and", false);
      case BO_LOr:
        return emitSimpleBinOp(LHS, RHS, ".or", false);
      case BO_MulAssign: case BO_DivAssign: case BO_RemAssign:
      case BO_AddAssign: case BO_SubAssign: case BO_AndAssign:
      case BO_XorAssign: case BO_OrAssign: case BO_ShrAssign:
      case BO_ShlAssign:
        IsAssign = true;
      // These operators are the same in dart and C:
      case BO_And: case BO_Xor: case BO_Or: case BO_Mul: case BO_Div:
      case BO_Rem: case BO_Add: case BO_Sub: case BO_LT: case BO_GT:
      case BO_LE: case BO_GE: case BO_Shl: case BO_Shr:
        if (IsAssign)
          Opc = BinaryOperator::getOpForCompoundAssignment(Opc);
        return emitSimpleBinOp(LHS, RHS,
          BinaryOperator::getOpcodeStr(Opc).str().c_str(), IsAssign);
      // C++ operators, not supported
      case BO_PtrMemD: case BO_PtrMemI:
        return false;
    }
  }

  bool TraverseUnaryOperator(UnaryOperator *O) {
    bool Ret = TraverseStmt(O->getSubExpr());
    switch (O->getOpcode()) {
      default:
        O->dump();
        return false;
      case UO_PostInc:
        OS << ".postinc()";
        break;
      case UO_PostDec:
        OS << ".postdec()";
        break;
      case UO_PreInc:
        OS << ".inc()";
        break;
      case UO_PreDec:
        OS << ".dec()";
        break;
      case UO_AddrOf:
        OS << ".addressOf()";
        break;
      case UO_Deref:
        OS << ".dereference()";
        break;
      case UO_Minus:
        OS << ".neg()";
      case UO_Plus:
        break;
    }
    return Ret;
  }

  bool TraverseUnaryExprOrTypeTraitExpr(UnaryExprOrTypeTraitExpr *E) {
    QualType TypeToSize = E->getTypeOfArgument();
    if (C.getAsVariableArrayType(TypeToSize)) {
      // VLAs not supported.
      return false;
    }
    // size_t is unsigned long
    OS << "(new DartCUnsignedLong.fromInt(" << E->EvaluateKnownConstInt(C) <<
      "))";
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

  bool TraverseRecordType(RecordType *T) {
    OS << "DartCComposite";
    return true;
  }

  bool TraverseArrayType(ArrayType *t) {
    // Note: This only works for the x86-64 definition of va_args
    if (t->getElementType().getCanonicalType() == C.getVaListTagType())
      OS << "va_list";
    else 
      OS << "DartCComposite";
    return true;
  }

  bool TraversePointerType(PointerType *t) {
    if (t->isFunctionPointerType())
      OS << "DartCFunctionPointer";
    else
      OS << "DartCPointer";
    return true;
  }

  bool TraverseBuiltinType(BuiltinType *t) {
    if (t->isVoidType())
      OS << "void";
    else
      OS << DartCClassForCBuiltin(t);
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
    OS << "return (";
    bool ret = TraverseStmt(s->getRetValue());
    OS << ").copy()";
    return ret;
  }

#pragma mark Literals

  bool VisitStringLiteral(StringLiteral *S) {
    StringRef Bytes = S->getBytes();
    OS << "(new DartCComposite.fromCString([";
    for (int Byte : Bytes)
      OS << Byte << ", ";
    OS << "0]))";
    return true;
  }

  bool VisitIntegerLiteral(IntegerLiteral *il) {
    OS << "(new " << DartCClassForCBuiltin(il->getType()) <<
          ".fromInt(" << il->getValue() << "))";
    return true;
  }
};

class DartWriterConsumer : public ASTConsumer {
public:
  virtual void HandleTranslationUnit(ASTContext &ctx) {
    DartWriter dartWriter(ctx);
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

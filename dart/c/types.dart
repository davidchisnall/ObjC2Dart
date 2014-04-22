import 'dart:typed_data';

import '../libc/stdlib.dart';
import '../libc/string.dart';

/**
 * Represents a piece of memory.
 * 
 * Addresses are made up of, from most to least significant:
 *  - 32 bits object ID
 *  - 29 bits offset
 *  - 3 bits alignment
 */
class C__Memory {
  // Counter used for memory object ID.
  static int _objectID = 0;
  
  /**
   * The base address of the memory. 
   */
  int _baseAddress;
  int get baseAddress => _baseAddress;
  
  /**
   * The data.
   */
  ByteBuffer _data;
  ByteBuffer get data => _data;
  
  C__Memory(int bytes) {
    // Set the object ID in the address.
    _baseAddress = _objectID << 32;
    ++_objectID;
    // Allocate the memory.
    Uint8List mem = new Uint8List(bytes);
    _data = mem.buffer;
  }
}

/**
 * Represents basic C types.
 */
class C__TYPE_DEFINITION {
  // Void.
  final bool isVoid;
  
  // Pointer.
  final bool isPointer;
  
  // Number.
  final bool isNumber;
  final bool isSigned;
  
  // Size.
  final int byteSize;
  
  /**
   * Private constructor. Please use static methods instead.
   */
  C__TYPE_DEFINITION(
      {bool isVoid, bool isPointer, bool isNumber, bool isSigned, bool isInteger, int byteSize}) :
    isVoid = isVoid, isPointer = isPointer, isNumber = isNumber, isSigned = isSigned,
    byteSize = byteSize;
  
  /**
   * Return a new instance of the type at the given memory location.
   */
  C__TYPE at(C__Memory memory, int offset) {
    if (this == C__TYPE_DEFINITION.int64_t) {
      return new C__TYPE_Int64(memory, offset);
    }
  }
  
  // Type definitions.
  
  /**
   * Returns a type definition for void.
   */
  static C__TYPE_DEFINITION get void_t => _void;
  static C__TYPE_DEFINITION _void = new C__TYPE_DEFINITION(isVoid: true, byteSize: 0);
  
  /**
   * Returns a type definition for a pointer.
   */
  static C__TYPE_DEFINITION get pointer_t => _pointer;
  static C__TYPE_DEFINITION _pointer = new C__TYPE_DEFINITION(isPointer: true, byteSize: 8);
  
  /**
   * Return a type defintion for a signed 64-bit integer.
   */
  static C__TYPE_DEFINITION get int64_t => _int64;
  static C__TYPE_DEFINITION _int64 =
      new C__TYPE_DEFINITION(isNumber: true, isSigned: true, byteSize: 8);
}

/**
 * Common superclass for all C types.
 */
abstract class C__TYPE {
  /**
   * The type definition.
   */
  C__TYPE_DEFINITION get definition => _definition;
  C__TYPE_DEFINITION _definition;
  
  /**
   * The memory storing the data.
   */
  C__Memory get memory => _memory;
  C__Memory _memory;
  
  /**
   * The offset in the memory, in bytes.
   */
  int get offset => _offset;
  int _offset;
  
  /**
   * The address.
   */
  int get address => memory.baseAddress + offset;
  
  /**
   * A view on the memory at the offset.
   */
  ByteData get view => _view;
  ByteData _view;
  
  /**
   * Initialise the type with the given definition, memory and offset in bytes.
   */
  C__TYPE(C__TYPE_DEFINITION definition, C__Memory memory, int offset) :
    _definition = definition, _memory = memory, _offset = offset, 
    _view = new ByteData.view(memory.data, offset);
  
  C__TYPE set(C__TYPE newValue) {
    if (definition != newValue.definition) {
      throw new UnsupportedError("Types must explicitly be casted before assigning");
    }
    C__memset(pointer(), 0, definition.byteSize);
    C__memcpy(pointer(), newValue.pointer(), definition.byteSize);
  }
  
  /**
   * Returns a C pointer to this instance.
   */
  C__TYPE_Pointer pointer() {
    return new C__TYPE_Pointer.toObject(this);
  }
}

/**
 * Represents a void type.
 */
class C__TYPE_Void extends C__TYPE {
  C__TYPE_Void(C__Memory memory, int offset) : super(C__TYPE_DEFINITION.void_t, memory, offset);
}

/**
 * Represents a 64-bit integer.
 */
class C__TYPE_Int64 extends C__TYPE {
  C__TYPE_Int64(C__Memory memory, int offset) : super(C__TYPE_DEFINITION.int64_t, memory, offset);
}

/**
 * Represents an integer literal.
 */
class C__TYPE_IntegerLiteral extends C__TYPE_Int64 {
  C__TYPE_IntegerLiteral(int literal) : 
    super(new C__Memory(C__TYPE_DEFINITION.int64_t.byteSize), 0) {
    view.setInt64(0, literal);
  }
  
  C__TYPE set(C__TYPE newValue) {
    throw new UnsupportedError("Cannot set literal");
  }
}

/**
 * Represents a pointer.
 */
class C__TYPE_Pointer extends C__TYPE {
  /*
   * The object this pointer points to.
   */
  C__TYPE get pointee => _pointee;
  C__TYPE _pointee;
  
  /**
   * Initialises a new pointer not pointing anywhere in particular.
   */
  C__TYPE_Pointer(C__Memory memory, int offset) :
    super(C__TYPE_DEFINITION.pointer_t, memory, offset);
  
  /**
   * Initialises a pointer pointing to the given object.
   */
  C__TYPE_Pointer.toObject(C__TYPE pointee) : 
    super(C__TYPE_DEFINITION.pointer_t, new C__Memory(C__TYPE_DEFINITION.pointer_t.byteSize), 0), 
    _pointee = pointee {
    view.setInt64(0, pointee.address);
  }
  
  /**
   * Initialises a pointer pointing to an area of memory.
   */
  C__TYPE_Pointer.toMemory(C__Memory memory, int offset) :
    this.toObject(new C__TYPE_Void(memory, offset));
  
  C__TYPE set(C__TYPE newValue) {
    super.set(newValue);
    C__TYPE_Pointer newPointer = newValue;
    _pointee = newPointer.pointee;
  }
}

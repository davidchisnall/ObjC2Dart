import 'dart:typed_data';


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
   * Return a new instance of the type.
   */
  C__TYPE create(C__Memory memory, int offset) {
    if (this == C__TYPE_DEFINITION.int64_t) {
      return new C__TYPE_Int64(memory, offset);
    }
  }
  
  // Type definitions.
  
  /**
   * Returns a type definition for void.
   */
  static C__TYPE_DEFINITION get void_t => _void;
  static C__TYPE_DEFINITION _void = new C__TYPE_DEFINITION(isVoid: true);
  
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
  
  /**
   * Returns a C pointer to this instance.
   */
  C__TYPE_Pointer pointer();
}


/**
 * Represents a 64-bit integer.
 */
class C__TYPE_Int64 extends C__TYPE {
  
  C__TYPE_Int64(C__Memory memory, int offset) : super(C__TYPE_DEFINITION.int64_t, memory, offset);
  
  C__TYPE_Pointer pointer() {
    // TODO
    return null;
  }
  
  C__TYPE setLiteral(int literal) {
    view.setInt64(0, literal);
  }
  
  int getLiteral() {
    return view.getInt64(0);
  }
}


/**
 * Represents a pointer.
 */
// TODO
class C__TYPE_Pointer extends C__TYPE {
  C__TYPE_Pointer(C__Memory memory, int offset) :
    super(C__TYPE_DEFINITION.pointer_t, memory, offset);
  
  C__TYPE_Pointer pointer() {
    return null;
  }
}


/**
 * Allocates |bytes| bytes of memory.
 */
C__TYPE_Pointer C__malloc(int bytes) {
  // TODO
}

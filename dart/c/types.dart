import 'dart:typed_data';

import '../libc/string.dart';

/**
 * Stores the base address -> C__Memory instance mapping. 
 */
Map<int, C__Memory> C__Memory_Map = new Map();

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
    C__Memory_Map[_baseAddress] = this;
  }
}

/**
 * Represents basic C types.
 */
class C__TYPE_DEFINITION {
  // Void.
  final bool isVoid;
  
  // Pointer.
  final int pointerLevel;
  
  // Number.
  final bool isNumber;
  final bool isSigned;
  
  // Size.
  int get byteSize => pointerLevel > 0 ? C__TYPE_DEFINITION.pointer_width : _byteSize;
  final int _byteSize;
  
  /**
   * Private constructor. Please use static methods instead.
   */
  C__TYPE_DEFINITION(int pointerLevel, {bool isVoid, bool isNumber, bool isSigned, int byteSize}) :
    isVoid = isVoid, pointerLevel = pointerLevel, isNumber = isNumber, isSigned = isSigned,
    _byteSize = byteSize;
  
  /**
   * Return a new instance of the type at the given memory location.
   */
  C__TYPE at(C__Memory memory, int offset) {
    if (this.pointerLevel > 0) {
      return new C__TYPE_Pointer.toMemory(memory, offset);
    } else if (this == C__TYPE_DEFINITION.int64_t) {
      return new C__TYPE_Int64(memory, offset);
    }
  }
  
  // Type definitions.
  
  /**
   * Returns a type definition for void.
   */
  static C__TYPE_DEFINITION get void_t => _void;
  static C__TYPE_DEFINITION _void = new C__TYPE_DEFINITION(0, isVoid: true, byteSize: 0);
  
  /**
   * Return a type defintion for a signed 64-bit integer.
   */
  static C__TYPE_DEFINITION get int64_t => _int64;
  static C__TYPE_DEFINITION _int64 =
      new C__TYPE_DEFINITION(0, isNumber: true, isSigned: true, byteSize: 8);
  
  /**
   * Returns the width of a pointer.
   */
  static int get pointer_width => 8;
  
  /**
   * Returns a type definition for a pointer to this type definition.
   */
  C__TYPE_DEFINITION get pointer_t =>
      new C__TYPE_DEFINITION(pointerLevel + 1,
          isVoid: isVoid, isNumber: isNumber, isSigned: isSigned, byteSize: _byteSize);
  
  /**
   * Returns a type definition for the type this pointer points to, or null if this type is not a
   * pointer.
   */
  C__TYPE_DEFINITION get target_t {
    if (pointerLevel > 0) {
      return new C__TYPE_DEFINITION(pointerLevel - 1,
          isVoid: isVoid, isNumber: isNumber, isSigned: isSigned, byteSize: _byteSize);
    } else {
      return null;
    }
  }
  
  bool operator==(var other) {
    return super == other || (other is C__TYPE_DEFINITION && isVoid == other.isVoid &&
        pointerLevel == other.pointerLevel && isNumber == other.isNumber &&
        isSigned == other.isSigned && byteSize == other.byteSize);
  }
  
  int get hashCode {
    return (isVoid ? 0 : 1) ^ (isNumber ? 2 : 4) ^ (isSigned ? 8 : 16) ^ byteSize ^ pointerLevel;
  }
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
  
  /**
   * Sets the given value in the memory of the variable.
   */
  C__TYPE set(C__TYPE newValue) {
    if (definition != newValue.definition) {
      throw new UnsupportedError("Types must explicitly be casted before assigning");
    }
    C__memcpy(pointer(), newValue.pointer(), definition.byteSize);
    return this;
  }
  
  /**
   * Returns a C pointer to this instance.
   */
  C__TYPE_Pointer pointer() {
    return new C__TYPE_Pointer.toObject(this);
  }
  
  /**
   * Checks equality.
   */
  bool operator==(var other) {
    return super == other || (other is C__TYPE && other.view.getInt64(0) == this.view.getInt64(0));
  }
  
  /**
   * Hash code.
   */
  int get hashCode {
    return this.view.getInt64(0).hashCode;
  }
}

/**
 * Represents an unknown type.
 * Note: Only used internally, for pointers.
 */
class C__TYPE_Void extends C__TYPE {
  C__TYPE_Void(C__Memory memory, int offset) : super(C__TYPE_DEFINITION.void_t, memory, offset);

  /**
   * Return a new instance of the type backed by the same data as the given variable.
   */
  C__TYPE_Void.from(C__TYPE variable) : this(variable.memory, variable.offset);

  /**
   * Allocate a new instance on the stack.
   */
  C__TYPE_Void.local() : this(new C__Memory(C__TYPE_DEFINITION.void_t.byteSize), 0);
}

/**
 * Represents a 64-bit integer.
 */
class C__TYPE_Int64 extends C__TYPE {
  C__TYPE_Int64(C__Memory memory, int offset) : super(C__TYPE_DEFINITION.int64_t, memory, offset);

  /**
   * Return a new instance of the type backed by the same data as the given variable.
   */
  C__TYPE_Int64.from(C__TYPE variable) : this(variable.memory, variable.offset);

  /**
   * Allocate a new instance on the stack.
   */
  C__TYPE_Int64.local() : this(new C__Memory(C__TYPE_DEFINITION.int64_t.byteSize), 0);
  
  /**
   * Initialises a 64-bit integer literal.
   */
  C__TYPE_Int64.literal(int literal) : 
    super(C__TYPE_DEFINITION.int64_t, new C__Memory(C__TYPE_DEFINITION.int64_t.byteSize), 0) {
    view.setInt64(0, literal);
  }
  
  bool operator<(C__TYPE_Int64 other) {
    return view.getInt64(0) < other.view.getInt64(0);
  }
  
  dynamic inc() {
    view.setInt64(0, view.getInt64(0) + 1);
    return this;
  }
}

/**
 * Represents a pointer.
 */
class C__TYPE_Pointer extends C__TYPE {
  /*
   * The object this pointer points to.
   */
  C__TYPE get pointee {
    if (_pointing != null) {
      return definition.target_t.at(_pointing, _pointerOffset);
    } else {
      // Try to reconstruct pointer.
      var baseAddress = (this.view.getInt64(0) >> 32) << 32;
      _pointing = C__Memory_Map[baseAddress];
      if (_pointing == null) {
        throw new StateError('The memory chunk this pointer points to cannot be found');
      }
      _pointerOffset = this.view.getInt64(0) & ((1 << 33) - 1);
      return pointee;
    }
  }
  C__Memory _pointing;
  int _pointerOffset;
  
  /**
   * The memory chunk this pointer points to.
   */
  C__Memory get memoryPointedTo {
    if (_pointing == null) {
      pointee;
    }
    return _pointing;
  }
  
  /**
   * Initialises a new pointer not pointing anywhere in particular.
   */
  C__TYPE_Pointer(C__Memory memory, int offset, C__TYPE_DEFINITION pointeeType) :
    super(pointeeType.pointer_t, memory, offset), _pointerOffset = 0 {
  }

  /**
   * Return a new instance of the type backed by the same data as the given variable.
   */
  C__TYPE_Pointer.from(C__TYPE variable, C__TYPE_DEFINITION pointeeType) :
    this(variable.memory, variable.offset, pointeeType);

  /**
   * Allocate a new instance on the stack.
   */
  C__TYPE_Pointer.local(C__TYPE_DEFINITION pointeeType) :
    this(new C__Memory(C__TYPE_DEFINITION.pointer_width), 0, pointeeType);
  
  /**
   * Initialises a pointer pointing to the given object.
   */
  C__TYPE_Pointer.toObject(C__TYPE pointee) :
    super(pointee.definition.pointer_t, new C__Memory(C__TYPE_DEFINITION.pointer_width), 0), 
    _pointing = pointee.memory, _pointerOffset = pointee.offset {
    view.setInt64(0, pointee.address);
  }
  
  /**
   * Initialises a pointer pointing to an area of memory.
   */
  C__TYPE_Pointer.toMemory(C__Memory memory, int offset) :
    this.toObject(new C__TYPE_Void(memory, offset));
  
  C__TYPE set(C__TYPE newValue) {
    if (definition != newValue.definition) {
      throw new UnsupportedError("Types must explicitly be casted before assigning");
    }
    view.setInt64(0, newValue.view.getInt64(0));
    C__TYPE_Pointer newPointer = newValue;
    _pointing = newPointer._pointing;
    _pointerOffset = newPointer._pointerOffset;
    return this;
  }
}

class C__ARRAY {
  
}

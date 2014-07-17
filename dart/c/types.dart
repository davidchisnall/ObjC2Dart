import 'dart:typed_data';


/**
 * Stores the object id -> C__Memory instance mapping.
 */
Map<int, DartCMemory> dartCMemoryMap = new Map();

/**
 * Represents a single allocation.
 *
 * Addresses are made up of, from most to least significant:
 *  - 32 bits object ID
 *  - 29 bits offset
 *  - 3 bits alignment
 */
class DartCMemory {
  // Counter used for memory object ID.
  static int _objectID = 0;

  /**
   * The base address of the memory.  This is 0 for any object whose
   * address is not taken and lazily allocated the first time its address
   * is taken.
   */
  int _baseAddress = 0;
  int get baseAddress {
    if (_baseAddress == 0) {
      // Set the object ID in the address.
      _baseAddress = _objectID++;
      // For now, we don't support allocating more than 2^32 objects over the
      // lifetime of a program.
      assert(_baseAddress < 0xffffffff);
      dartCMemoryMap[_baseAddress] = this;
    }
    return _baseAddress;
  }

  /**
   * 'Free' the underlying memory.  The memory will not be deallocated until the
   * garbage collector detects that it is free.  Calling this removes the
   * memory map entry, ensuring that it is not possible to construct a pointer
   * to this object from an integer.
   */
  void free() {
    if (_baseAddress != 0) {
      dartCMemoryMap[_baseAddress] = null;
    }
  }

  Map<int, DartCPointer> pointers;

  DartCPointer getPointerFromInteger(int offset, int ptr) {
    DartCPointer ptr = pointers[offset];
    if (ptr != null) {
      return ptr;
    }
    // TODO: Pluggable policies for pointers that we're trying to reconstruct
    // from integers
    return new DartCPointer.fromUInt64(ptr);
  }
  /**
   * Get a pointer value.  If no pointer was stored here, then try to calculate
   * one from the data.
   */
  DartCPointer getPointer(int offset) => getPointerFromInteger(offset,
      getUInt64(offset));

  /**
   * Fill in all pointer values that overlap the data that we're reading.
   * This ensures that we're computing numerical values for every pointer that
   * is stored.  It is done lazily because we don't want to assign unique
   * identifiers to short-lived objects.
   */
  void checkPointers(int offset, int size) {
    // Fast path to skip this if this has no pointers
    if (pointers.isEmpty) return;
    int start = (offset - 8).clamp(0, _bytes);
    int end = offset + size.clamp(0, _bytes - 8);
    for (int i = start; i <= end; i++) {
      DartCPointer ptr = pointers[i];
      if (ptr != null) {
        data.setUint64(i, ptr.intValue());
      }
    }
  }

  /**
   * Invalidate any pointers that overlap with some data that we're about to
   * write.  We'll try to recompute them from integers if possible...
   */
  void invalidatePointers(int offset, int size) {
    // Fast path to skip this if this has no pointers
    if (pointers.isEmpty) return;
    int start = (offset - 8).clamp(0, _bytes);
    int end = offset + size.clamp(0, _bytes - 8);
    for (int i = start; i <= end; i++) {
      pointers.remove(i);
    }
  }

  /**
   * Primitive accessor methods.  These each read a value from the C memory at
   * the specified offset.
   */
  int getUInt64(int offset) {
    checkPointers(offset, 8);
    return data.getUint64(offset);
  }
  int getInt64(int offset) {
    checkPointers(offset, 8);
    return data.getInt64(offset);
  }
  int getUInt32(int offset) {
    checkPointers(offset, 4);
    return data.getUint64(offset);
  }
  int getInt32(int offset) {
    checkPointers(offset, 4);
    return data.getInt64(offset);
  }
  int getUInt16(int offset) {
    checkPointers(offset, 2);
    return data.getUint64(offset);
  }
  int getInt16(int offset) {
    checkPointers(offset, 2);
    return data.getInt64(offset);
  }
  int getUInt8(int offset) {
    checkPointers(offset, 1);
    return data.getUint64(offset);
  }
  int getInt8(int offset) {
    checkPointers(offset, 1);
    return data.getInt64(offset);
  }
  double getFloat32(int offset) {
    checkPointers(offset, 4);
    return data.getFloat32(offset);
  }
  double getFloat64(int offset) {
    checkPointers(offset, 8);
    return data.getFloat64(offset);
  }
  void setUInt64(int offset, int value) {
    checkPointers(offset, 8);
    data.setUint64(offset, value);
  }
  void setInt64(int offset, int value) {
    checkPointers(offset, 8);
    data.setInt64(offset, value);
  }
  void setUInt32(int offset, int value) {
    checkPointers(offset, 4);
    data.setUint64(offset, value);
  }
  void setInt32(int offset, int value) {
    checkPointers(offset, 4);
    data.setInt64(offset, value);
  }
  void setUInt16(int offset, int value) {
    checkPointers(offset, 2);
    data.setUint64(offset, value);
  }
  void setInt16(int offset, int value) {
    checkPointers(offset, 2);
    data.setInt64(offset, value);
  }
  void setUInt8(int offset, int value) {
    checkPointers(offset, 1);
    data.setUint64(offset, value);
  }
  void setInt8(int offset, int value) {
    checkPointers(offset, 1);
    data.setInt64(offset, value);
  }
  void setFloat32(int offset, double value) {
    checkPointers(offset, 4);
    data.setFloat32(offset, value);
  }
  void setFloat64(int offset, double value) {
    checkPointers(offset, 8);
    data.setFloat64(offset, value);
  }


  /**
   * The data.
   */
  ByteData _data;
  ByteData get data => _data;
  /**
   * Size of the data
   */
  int _bytes;

  DartCMemory.alloc(this._bytes) {
    // Allocate the memory.
    Uint8List mem = new Uint8List(_bytes);
    _data = new ByteData.view(mem.buffer);
  }

  void memcpy(DartCMemory other, int offset, int otherOffset, int length) {
    ByteData otherData = other.data;
    for (int i = 0; i < length; i++) {
      _data.setUint8(offset, otherData.getUint8(otherOffset));
      pointers[offset++] = other.pointers[otherOffset++];
    }
  }
}

/**
 * Common superclass for all C types.
 */
abstract class DartCObject {
  /**
   * The memory storing the data.
   */
  DartCMemory memory;

  /**
   * The size of the object.
   */
  int sizeof;
  /**
   * The offset within the memory of the start of this object.
   */
  int offset;

  /**
   * The address.
   */
  int get address => (memory.baseAddress << 32) + offset;

  /**
   * Initialise the type with the given definition, memory and offset in bytes.
   */
  DartCObject(this.memory, this.sizeof, this.offset);

  /**
   * Constructs a new object with a new backing store.
   */
  DartCObject.alloc(this.sizeof) {
    memory = new DartCMemory.alloc(sizeof);
  }

  /**
   * Sets the given value in the memory of the variable.
   */
  DartCObject set(DartCObject newValue) {
    // Make sure that we're copying from an object that is the same size.
    assert(sizeof == newValue.sizeof);
    memory.memcpy(newValue.memory, offset, newValue.offset, sizeof);
    return this;
  }
  /**
   * Returns a C pointer to this instance.
   */
  DartCPointer addressOf() {
    return new DartCPointer.pointerTo(this);
  }
  /**
   * Array or structure access: constructs a new object using a different part
   * of the underlying memory.  For example, given `int a[2]', calling
   * `constructAtOffset(4)` on the object encapsulating `a[0]` will give `a[1]`.
   */
  DartCObject constructAtOffset(int anOffset);
}

/**
 * Abstract class encapsulating all arithmetic types
 * (things that are not structs, unions, or arrays).
 */
abstract class DartCArithmetic extends DartCObject {
  DartCArithmetic(DartCMemory mem, int size, int offset) : super(mem, size,
      offset);
  DartCArithmetic.alloc(int size) : super.alloc(size);
  /**
   * Abstract accessors.  Gets the value as one of the primitive C types.
   */
  DartCObject unsignedCharValue();
  DartCObject signedCharValue();
  DartCObject unsignedShortValue();
  DartCObject signedShortValue();
  DartCObject unsignedIntValue();
  DartCObject signedIntValue();
  DartCObject unsignedLongValue();
  DartCObject signedLongValue();
  DartCObject floatValue();
  DartCObject doubleValue();
  /**
   * Helpers for aliases.
   */
  DartCObject charValue() {
    return unsignedCharValue();
  }
  DartCObject unsignedLongLongValue() {
    return unsignedLongValue();
  }
  DartCObject signedLongLongValue() {
    return signedLongValue();
  }
}

/**
 * Abstract superclass for all primitive integer types.
 *
 * Type promotion for arithmetic is handled in the compiler, so concrete
 * subclasses of this just need to be able to construct any of the required
 * integer types.  We do this by getting the value as a Dart integer and then
 * constructing the correct concrete subclass.
 */
abstract class DartCInteger extends DartCArithmetic {
  DartCInteger(DartCMemory memory, int size, int offset) : super(memory, size,
      offset);
  DartCInteger.withSize(int size) : super.alloc(size);

  /**
   * Access this value as a Dart integer.
   */
  int intValue();
  /**
   * Set this value from a Dart integer.
   */
  void setIntValue(int v);

  /**
   * Construct an instance of the subclass
   */
  DartCInteger construct();
  /**
   * Constructs a new instance of this class from the Dart integer.
   */
  DartCInteger constructFromInt(int v) {
    DartCInteger i = construct();
    i.setIntValue(v);
    return i;
  }

  DartCArithmetic operator <(DartCInteger other) => new DartCSignedInt.fromInt(
      (intValue() < other.intValue()) ? 1 : 0);
  DartCArithmetic eq(DartCInteger other) => new DartCSignedInt.fromInt(
      (intValue() == other.intValue()) ? 1 : 0);
  DartCArithmetic ne(DartCInteger other) => new DartCSignedInt.fromInt(
      (intValue() == other.intValue()) ? 1 : 0);
  DartCArithmetic operator <=(DartCInteger other) => new DartCSignedInt.fromInt(
      (intValue() <= other.intValue()) ? 1 : 0);
  DartCArithmetic operator >(DartCInteger other) => new DartCSignedInt.fromInt(
      (intValue() > other.intValue()) ? 1 : 0);
  DartCArithmetic operator >=(DartCInteger other) => new DartCSignedInt.fromInt(
      (intValue() >= other.intValue()) ? 1 : 0);
  DartCInteger operator +(DartCInteger other) => constructFromInt(intValue() +
      other.intValue());
  DartCInteger operator -(DartCInteger other) => constructFromInt(intValue() -
      other.intValue());
  DartCInteger operator *(DartCInteger other) => constructFromInt(intValue() *
      other.intValue());
  DartCInteger operator /(DartCInteger other) => constructFromInt(intValue() ~/
      other.intValue());
  DartCInteger inc() {
    setIntValue(intValue() + 1);
    return this;
  }
  DartCInteger dec() {
    setIntValue(intValue() - 1);
    return this;
  }
  DartCInteger operator <<(DartCInteger other) => constructFromInt(intValue() <<
      other.intValue());
  DartCInteger operator >>(DartCInteger other) => constructFromInt(intValue() >>
      other.intValue());
  /**
   * Type cast operators.
   * FIXME: These don't propagate pointers, but should!
   */
  DartCObject unsignedCharValue() => new DartCUnsignedChar.fromInt(intValue());
  DartCObject signedCharValue() => new DartCSignedChar.fromInt(intValue());
  DartCObject unsignedShortValue() => new DartCUnsignedShort.fromInt(intValue()
      );
  DartCObject signedShortValue() => new DartCUnsignedShort.fromInt(intValue());
  DartCObject unsignedIntValue() => new DartCUnsignedInt.fromInt(intValue());
  DartCObject signedIntValue() => new DartCUnsignedInt.fromInt(intValue());
  DartCObject unsignedLongValue() => new DartCUnsignedLong.fromInt(intValue());
  DartCObject signedLongValue() => new DartCUnsignedLong.fromInt(intValue());
  DartCObject floatValue() => new DartCFloat.fromNum(intValue());
  DartCObject doubleValue() => new DartCDouble.fromNum(intValue());
  DartCPointer pointerValue() => memory.getPointerFromInteger(offset, intValue());

}
abstract class DartCFloating extends DartCArithmetic {
  DartCFloating(DartCMemory memory, int size, int offset) : super(memory, size,
      offset);
  DartCFloating.withSize(int size) : super.alloc(size);

  /**
   * Access this value as a Dart number.
   */
  num numValue();
  /**
   * Set this value from a Dart number.
   */
  void setNumValue(num v);
  int intValue() => numValue().round();
  void setIntValue(int v) => setNumValue(v);
  /**
   * Construct an instance of the subclass
   */
  DartCFloating construct();
  /**
   * Constructs a new instance of this class from the Dart integer.
   */
  DartCFloating constructFromNum(num v) {
    DartCFloating i = construct();
    i.setNumValue(v);
    return i;
  }

  DartCArithmetic operator <(DartCFloating other) => new DartCSignedInt.fromInt(
      (numValue() < other.numValue()) ? 1 : 0);
  DartCArithmetic eq(DartCFloating other) => new DartCSignedInt.fromInt(
      (numValue() == other.numValue()) ? 1 : 0);
  DartCArithmetic ne(DartCFloating other) => new DartCSignedInt.fromInt(
      (numValue() == other.numValue()) ? 1 : 0);
  DartCArithmetic operator <=(DartCFloating other) =>
      new DartCSignedInt.fromInt((numValue() <= other.numValue()) ? 1 : 0);
  DartCArithmetic operator >(DartCFloating other) => new DartCSignedInt.fromInt(
      (numValue() > other.numValue()) ? 1 : 0);
  DartCArithmetic operator >=(DartCFloating other) =>
      new DartCSignedInt.fromInt((numValue() >= other.numValue()) ? 1 : 0);
  DartCFloating operator +(DartCFloating other) => constructFromNum(numValue() +
      other.numValue());
  DartCFloating operator -(DartCFloating other) => constructFromNum(numValue() -
      other.numValue());
  DartCFloating operator *(DartCFloating other) => constructFromNum(numValue() *
      other.numValue());
  DartCFloating operator /(DartCFloating other) => constructFromNum(numValue() /
      other.numValue());
  DartCFloating inc() {
    setNumValue(numValue() + 1);
    return this;
  }
  DartCFloating dec() {
    setNumValue(numValue() - 1);
    return this;
  }
  /**
   * Type cast operators.
   */
  DartCObject unsignedCharValue() => new DartCUnsignedChar.fromInt(intValue());
  DartCObject signedCharValue() => new DartCSignedChar.fromInt(intValue());
  DartCObject unsignedShortValue() => new DartCUnsignedShort.fromInt(intValue()
      );
  DartCObject signedShortValue() => new DartCUnsignedShort.fromInt(intValue());
  DartCObject unsignedIntValue() => new DartCUnsignedInt.fromInt(intValue());
  DartCObject signedIntValue() => new DartCUnsignedInt.fromInt(intValue());
  DartCObject unsignedLongValue() => new DartCUnsignedLong.fromInt(intValue());
  DartCObject signedLongValue() => new DartCUnsignedLong.fromInt(intValue());
  DartCObject floatValue() => new DartCFloat.fromNum(numValue());
  DartCObject doubleValue() => new DartCDouble.fromNum(numValue());
}
/**
 * Class encapsulating all structures, arrays and unions.  These types only
 * support copying and constructing objects wrapping their fields.
 */
class DartCComposite extends DartCObject {
  DartCComposite.fromMemory(DartCMemory mem, int size, int offset) : super(mem,
      size, offset);
  DartCComposite.alloc(int size) : super.alloc(size);
  DartCObject unsignedCharAtOffset(int anOffset) =>
      new DartCUnsignedChar.fromMemory(memory, offset + anOffset);
  DartCObject signedCharAtOffset(int anOffset) =>
      new DartCSignedChar.fromMemory(memory, offset + anOffset);
  DartCObject unsignedShortAtOffset(int anOffset) =>
      new DartCUnsignedShort.fromMemory(memory, offset + anOffset);
  DartCObject signedShortAtOffset(int anOffset) =>
      new DartCSignedShort.fromMemory(memory, offset + anOffset);
  DartCObject unsignedIntAtOffset(int anOffset) =>
      new DartCUnsignedInt.fromMemory(memory, offset + anOffset);
  DartCObject signedIntAtOffset(int anOffset) => new DartCSignedInt.fromMemory(
      memory, offset + anOffset);
  DartCObject unsignedLongAtOffset(int anOffset) =>
      new DartCUnsignedLong.fromMemory(memory, offset + anOffset);
  DartCObject signedLongAtOffset(int anOffset) =>
      new DartCSignedLong.fromMemory(memory, offset + anOffset);
  DartCObject floatAtOffset(int anOffset) => new DartCFloat.fromMemory(memory,
      offset + anOffset);
  DartCObject doubleAtOffset(int anOffset) => new DartCDouble.fromMemory(memory,
      offset + anOffset);
  DartCObject pointerAtOffset(int anOffset) => memory.getPointer(offset +
      anOffset);
  DartCObject compositeAtOffset(int anOffset, int size) =>
      new DartCComposite.fromMemory(memory, size, offset + anOffset);
  DartCObject constructAtOffset(int anOffset) => new DartCComposite.fromMemory(
      memory, sizeof, offset + anOffset);
}

class DartCFloat extends DartCFloating {
  static final int bytes = 32;
  static final int bits = bytes * 8;
  num numValue() => memory.getFloat32(offset);
  void setNumValue(num v) => memory.setFloat32(offset, v);
  DartCFloat.fromNum(num n) : super.withSize(bytes) {
    setNumValue(n);
  }
  DartCFloat.fromMemory(DartCMemory memory, int offset) : super(memory, bits,
      offset);
  DartCFloat() : this.fromMemory(new DartCMemory.alloc(bits), 0);
  DartCFloating construct() => new DartCFloat();
  DartCObject constructAtOffset(int anOffset) => new DartCFloat.fromMemory(
      memory, offset + anOffset);
}
class DartCDouble extends DartCFloating {
  static final int bytes = 32;
  static final int bits = bytes * 8;
  num numValue() => memory.getFloat64(offset);
  void setNumValue(num v) => memory.setFloat64(offset, v);
  DartCDouble.fromNum(num n) : super.withSize(bytes) {
    setNumValue(n);
  }
  DartCDouble.fromMemory(DartCMemory memory, int offset) : super(memory, bits,
      offset);
  DartCDouble() : this.fromMemory(new DartCMemory.alloc(bits), 0);
  DartCFloating construct() => new DartCDouble();
  DartCObject constructAtOffset(int anOffset) => new DartCDouble.fromMemory(
      memory, offset + anOffset);
}


class DartCSignedChar extends DartCInteger {
  static final int bytes = 1;
  static final int bits = bytes * 8;
  int intValue() => memory.getInt8(offset);
  void setIntValue(int v) => memory.setInt8(offset, v.toUnsigned(bits));
  DartCSignedChar.fromInt(int n) : super.withSize(bytes) {
    setIntValue(n);
  }
  DartCSignedChar.fromMemory(DartCMemory memory, int offset) : super(memory,
      bits, offset);
  DartCSignedChar() : this.fromMemory(new DartCMemory.alloc(bits), 0);
  DartCInteger construct() => new DartCSignedChar();
  DartCObject constructAtOffset(int anOffset) => new DartCSignedChar.fromMemory(
      memory, offset + anOffset);
}
class DartCUnsignedChar extends DartCInteger {
  static final int bytes = 1;
  static final int bits = bytes * 8;
  int intValue() => memory.getUInt8(offset);
  void setIntValue(int v) => memory.setUInt8(offset, v.toSigned(bits));
  DartCUnsignedChar.fromInt(int n) : super.withSize(bytes) {
    setIntValue(n);
  }
  DartCUnsignedChar.fromMemory(DartCMemory memory, int offset) : super(memory,
      bits, offset);
  DartCUnsignedChar() : this.fromMemory(new DartCMemory.alloc(bits), 0);
  DartCInteger construct() => new DartCUnsignedChar();
  DartCObject constructAtOffset(int anOffset) =>
      new DartCUnsignedChar.fromMemory(memory, offset + anOffset);
}
class DartCSignedShort extends DartCInteger {
  static final int bytes = 1;
  static final int bits = bytes * 8;
  int intValue() => memory.getInt8(offset);
  void setIntValue(int v) => memory.setInt8(offset, v.toUnsigned(bits));
  DartCSignedShort.fromInt(int n) : super.withSize(bytes) {
    setIntValue(n);
  }
  DartCSignedShort.fromMemory(DartCMemory memory, int offset) : super(memory,
      bits, offset);
  DartCSignedShort() : this.fromMemory(new DartCMemory.alloc(bits), 0);
  DartCInteger construct() => new DartCSignedShort();
  DartCObject constructAtOffset(int anOffset) =>
      new DartCSignedShort.fromMemory(memory, offset + anOffset);
}
class DartCUnsignedShort extends DartCInteger {
  static final int bytes = 2;
  static final int bits = bytes * 8;
  int intValue() => memory.getUInt16(offset);
  void setIntValue(int v) => memory.setUInt16(offset, v.toSigned(bits));
  DartCUnsignedShort.fromInt(int n) : super.withSize(bytes) {
    setIntValue(n);
  }
  DartCUnsignedShort.fromMemory(DartCMemory memory, int offset) : super(memory,
      bits, offset);
  DartCUnsignedShort() : this.fromMemory(new DartCMemory.alloc(bits), 0);
  DartCInteger construct() => new DartCUnsignedShort();
  DartCObject constructAtOffset(int anOffset) =>
      new DartCUnsignedShort.fromMemory(memory, offset + anOffset);
}
class DartCSignedInt extends DartCInteger {
  static final int bytes = 2;
  static final int bits = bytes * 8;
  int intValue() => memory.getInt16(offset);
  void setIntValue(int v) => memory.setInt16(offset, v.toUnsigned(bits));
  DartCSignedInt.fromInt(int n) : super.withSize(bytes) {
    setIntValue(n);
  }
  DartCSignedInt.fromMemory(DartCMemory memory, int offset) : super(memory,
      bits, offset);
  DartCSignedInt() : this.fromMemory(new DartCMemory.alloc(bits), 0);
  DartCInteger construct() => new DartCSignedInt();
  DartCObject constructAtOffset(int anOffset) => new DartCSignedInt.fromMemory(
      memory, offset + anOffset);
}
class DartCUnsignedInt extends DartCInteger {
  static final int bytes = 4;
  static final int bits = bytes * 8;
  int intValue() => memory.getUInt32(offset);
  void setIntValue(int v) => memory.setUInt32(offset, v.toSigned(bits));
  DartCUnsignedInt.fromInt(int n) : super.withSize(bytes) {
    setIntValue(n);
  }
  DartCUnsignedInt.fromMemory(DartCMemory memory, int offset) : super(memory,
      bits, offset);
  DartCUnsignedInt() : this.fromMemory(new DartCMemory.alloc(bits), 0);
  DartCInteger construct() => new DartCUnsignedInt();
  DartCObject constructAtOffset(int anOffset) =>
      new DartCUnsignedInt.fromMemory(memory, offset + anOffset);
}
class DartCSignedLong extends DartCInteger {
  static final int bytes = 8;
  static final int bits = bytes * 8;
  int intValue() => memory.getInt64(offset);
  void setIntValue(int v) => memory.setInt64(offset, v.toUnsigned(bits));
  DartCSignedLong.fromInt(int n) : super.withSize(bytes) {
    setIntValue(n);
  }
  DartCSignedLong.fromMemory(DartCMemory memory, int offset) : super(memory,
      bits, offset);
  DartCSignedLong() : this.fromMemory(new DartCMemory.alloc(bits), 0);
  DartCInteger construct() => new DartCSignedLong();
  DartCObject constructAtOffset(int anOffset) => new DartCSignedLong.fromMemory(
      memory, offset + anOffset);
}
class DartCUnsignedLong extends DartCInteger {
  static final int bytes = 8;
  static final int bits = bytes * 8;
  int intValue() => memory.getUInt64(offset);
  void setIntValue(int v) => memory.setUInt64(offset, v.toSigned(bits));
  DartCUnsignedLong.fromInt(int n) : super.withSize(bytes) {
    setIntValue(n);
  }
  DartCUnsignedLong.fromMemory(DartCMemory memory, int offset) : super(memory,
      bits, offset);
  DartCUnsignedLong() : this.fromMemory(new DartCMemory.alloc(bits), 0);
  DartCInteger construct() => new DartCUnsignedLong();
  DartCObject constructAtOffset(int anOffset) =>
      new DartCUnsignedInt.fromMemory(memory, offset + anOffset);
}

/**
 * A C pointer.  C pointers either refer to a valid object, one element past a
 * valid object, or to null.  In this implementation, they can also hold
 * arbitrary numeric values, with a best-effort attempt to resurrect them being
 * made later.
 *
 * Pointers have a type associated with them.  Pointer casts require
 * reinterpreting the data, constructing a new underlying object backed by some
 * existing memory.
 */
class DartCPointer extends DartCObject {
  /**
   * The object that this is currently pointing to, or null if there is no such
   * object.
   */
  DartCObject baseObject;
  /**
   * The offset of this pointer.
   */
  int pointerOffset;
  /**
   */
  DartCObject _currentObject;
  /*
   * The object this pointer points to.
   */
  DartCObject dereference() {
    if (_currentObject == null) {
      if (offset == 0) {
        _currentObject = baseObject;
      } else {
        _currentObject = baseObject.constructAtOffset(0);
      }
    }
    return _currentObject;
  }

  /**
   * Returns the pointer interpreted as an integer
   */
  int intValue() {
    if (_currentObject == 0) {
      return pointerOffset;
    }
    // This will implicitly insert the base memory in the object map,
    // if required.
    return (_currentObject.memory.baseAddress << 32) + pointerOffset;
  }

  /**
   * Initialises a new pointer pointing to a specific object.
   */
  DartCPointer.pointerTo(DartCObject this.baseObject)
      : super.alloc(8);

  DartCPointer.fromUInt64(int intVal) : super.alloc(8) {
    offset = intVal.toUnsigned(32);
    DartCMemory mem = dartCMemoryMap[intVal >> 32];
    // Pointers constructed from integers are char*.  The compiler is
    // responsible for then casting them to the correct type.
    if (mem != null) {
      baseObject = new DartCUnsignedChar.fromMemory(mem, offset);
    }
  }

  /**
   * Construct a new pointer that is at a given offset from another.
   *
   * Note that this method *is* allowed to construct invalid pointers and so
   * must not dereference the pointer.
   */
  DartCPointer.atOffset(DartCPointer other, int deltaOffset) : super.alloc(8) {
    baseObject = other.baseObject;
    offset = other.offset + deltaOffset;
  }

  DartCPointer operator +(DartCInteger other) => new DartCPointer.atOffset(this,
      other.intValue());
  DartCPointer operator -(DartCInteger other) => new DartCPointer.atOffset(this,
      other.intValue());


  DartCObject index(DartCInteger index) {
    DartCObject obj = dereference();
    return obj.constructAtOffset(index.intValue() * obj.sizeof);
  }

  DartCObject unsignedCharValue() => new DartCUnsignedChar.fromInt(intValue());
  DartCObject signedCharValue() => new DartCSignedChar.fromInt(intValue());
  DartCObject unsignedShortValue() => new DartCUnsignedShort.fromInt(intValue()
      );
  DartCObject signedShortValue() => new DartCUnsignedShort.fromInt(intValue());
  DartCObject unsignedIntValue() => new DartCUnsignedInt.fromInt(intValue());
  DartCObject signedIntValue() => new DartCUnsignedInt.fromInt(intValue());
  DartCObject unsignedLongValue() => new DartCUnsignedLong.fromInt(intValue());
  DartCObject signedLongValue() => new DartCUnsignedLong.fromInt(intValue());
  DartCObject floatValue() => new DartCFloat.fromNum(intValue());
  DartCObject doubleValue() => new DartCDouble.fromNum(intValue());

  DartCObject constructAtOffset(int anOffset) => memory.getPointer(offset +
      anOffset);
}

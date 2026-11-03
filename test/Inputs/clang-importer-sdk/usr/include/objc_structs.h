@import Foundation;

struct StructOfNSStrings {
  __unsafe_unretained NSString *nsstr;
};

struct StructOfBlocks {
  void (^__unsafe_unretained _Nonnull block)(void);
};

struct StrongsInAStruct { // expected-note {{record 'StrongsInAStruct' contains strong references and cannot be imported without enabling experimental feature ImportCStructsWithArcFields}}
  __strong NSString *nsstr;
};

struct WeaksInAStruct { // expected-note {{record 'WeaksInAStruct' contains a weak reference and cannot be imported}}
  __weak NSString *nsstr;
};

// Types used when ImportCStructsWithArcFields is enabled.
@interface MYObject : NSObject
@end

struct StrongsInAStructArc {
  __strong MYObject *_Nonnull myobj;
};

void takeStrongArcStruct(struct StrongsInAStructArc s);
struct StrongsInAStructArc returnStrongArcStruct(void);

struct WeaksInAStructArc {
  __weak MYObject *_Nullable myobj;
};

@interface WeakArcStructBase : NSObject
- (struct WeaksInAStructArc)transformWeakArcStruct:
    (struct WeaksInAStructArc)value;
@end

struct WeakAndNonnull {
  __weak MYObject *_Nonnull myobj;
};

struct ConstWeakInAStruct {
  __weak MYObject *_Nullable const myobj;
};

struct MixedStrongWeakArc {
  __strong MYObject *_Nonnull strong;
  __weak MYObject *_Nullable weak;
  int tag;
};

void takeMixedArcStruct(struct MixedStrongWeakArc s);

struct WeakNSStringArc {
  __weak NSString *_Nullable name;
  int tag;
};

struct UnavailableArcStruct {
  __strong MYObject *_Nonnull myobj;
} NS_SWIFT_UNAVAILABLE("Use MySwiftType instead");

struct CNameForRenamedArcStruct {
  __strong MYObject *_Nonnull myobj;
} __attribute__((swift_name("RenamedArcStruct")));

// Nested struct with strong ARC fields should be imported.
struct InnerArcStruct {
  __strong MYObject *_Nonnull inner;
};
struct OuterArcStruct {
  struct InnerArcStruct nested;
  int tag;
};

// Struct with __weak fields should be imported with the feature enabled.
struct WeakInAStructArc {
  __weak MYObject *_Nullable weakobj;
};

// Struct nesting a __weak field should also be imported.
struct OuterWithWeakInner {
  struct WeakInAStructArc nested;
};

// Union with strong ARC fields should not be imported.
union UnionWithStrong {
  __strong MYObject *_Nonnull obj;
  void *_Nonnull raw;
};

// Struct containing a union with strong ARC fields should not be imported.
struct StructWithArcUnion {
  union UnionWithStrong u;
};

// Struct with a fixed-size array of weak references. The array field has no
// Swift representation, so it is omitted while its storage is preserved
// opaquely. The struct keeps its other fields and remains address-only.
struct WeakArrayArc {
  int tag;
  __weak MYObject *_Nullable values[2];
};

// Struct combining a fixed-size array of weak references with a fixed-size
// array of strong references. Both arrays are handled by the Clang-synthesized
// value witnesses of the address-only record.
struct WeakStrongArraysArc {
  __strong MYObject *_Nonnull strongs[2];
  __weak MYObject *_Nullable weaks[2];
};

// Struct with a fixed-size array of weak + _Nonnull elements. Like a scalar
// weak + _Nonnull field, this cannot be represented and rejects the record.
struct WeakArrayNonnullArc {
  __weak MYObject *_Nonnull values[2];
};

// Struct nesting a record with an opaque weak array.
struct OuterWithWeakArrayInner {
  struct WeakArrayArc nested;
  int other;
};

// Struct with an anonymous struct member containing a weak array. The array
// is omitted, even though it is injected as an indirect field, while its
// storage is preserved opaquely.
struct AnonWeakArrayHolder {
  struct {
    __weak MYObject *_Nullable hidden[2];
    int tag;
  };
  int y;
};

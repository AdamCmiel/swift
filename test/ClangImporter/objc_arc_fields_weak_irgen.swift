// RUN: %target-swift-frontend(mock-sdk: %clang-importer-sdk) -emit-ir -enable-experimental-feature ImportCStructsWithArcFields %s | %FileCheck %s

// REQUIRES: objc_interop
// REQUIRES: swift_feature_ImportCStructsWithArcFields

import Foundation
import objc_structs

// Structs with __weak fields are address-only. Their VWT operations use
// Clang-synthesized helper functions that call ObjC runtime weak operations
// (objc_copyWeak, objc_destroyWeak, etc.) directly.

// CHECK-LABEL: define {{.*}} @"$s{{.*}}testCreateAndDestroyWeak
// CHECK: alloca %TSo17WeaksInAStructArcV
// CHECK: call void @__destructor_8_w0
// CHECK: ret void
func testCreateAndDestroyWeak() {
  var s = WeaksInAStructArc()
  _ = s
}

// testCopyWeak is address-only: indirect sret return and indirect parameter.
// CHECK-LABEL: define {{.*}} @"$s{{.*}}testCopyWeak
// CHECK-SAME: ptr noalias sret(%TSo17WeaksInAStructArcV)
// CHECK-SAME: ptr noalias{{.*}}dereferenceable
// CHECK: call void @__copy_constructor_8_8_w0
// CHECK: ret void
func testCopyWeak(_ s: WeaksInAStructArc) -> WeaksInAStructArc {
  return s
}

// Nested weak structs must remain address-only and use Clang's recursively
// synthesized weak copy helper rather than memcpy.
// CHECK-LABEL: define {{.*}} @"$s{{.*}}testCopyNestedWeak
// CHECK-SAME: ptr noalias sret(%TSo18OuterWithWeakInnerV)
// CHECK-SAME: ptr noalias{{.*}}dereferenceable
// CHECK: call void @__copy_constructor_8_8_S_w0
// CHECK-NOT: llvm.memcpy
// CHECK: ret void
func testCopyNestedWeak(_ s: OuterWithWeakInner) -> OuterWithWeakInner {
  return s
}

// Field access uses objc_loadWeakRetained directly to match the
// Clang-synthesized VWT functions that use objc_copyWeak/objc_destroyWeak.
// CHECK-LABEL: define {{.*}} @"$s{{.*}}testWeakFieldAccess
// CHECK: call ptr @llvm.objc.loadWeakRetained
// CHECK: ret
func testWeakFieldAccess(_ s: WeaksInAStructArc) -> MYObject? {
  return s.myobj
}

// Mixed strong/weak structs are also address-only due to the weak field.
// CHECK-LABEL: define {{.*}} @"$s{{.*}}testCreateAndDestroyMixed
// CHECK: call void @__destructor_8_s0_w8
// CHECK: ret void
func testCreateAndDestroyMixed() {
  var s = MixedStrongWeakArc(strong: MYObject(), weak: nil, tag: 0)
  _ = s
}

// CHECK-LABEL: define {{.*}} @"$s{{.*}}testCopyMixed
// CHECK-SAME: ptr noalias sret(%TSo18MixedStrongWeakArcV)
// CHECK-SAME: ptr noalias{{.*}}dereferenceable
// CHECK: call void @__copy_constructor_8_8_s0_w8
// CHECK: ret void
func testCopyMixed(_ s: MixedStrongWeakArc) -> MixedStrongWeakArc {
  return s
}

// Storing to a weak field uses objc_storeWeak directly.
// CHECK-LABEL: define {{.*}} @"$s{{.*}}testWeakFieldStore
// CHECK: call ptr @llvm.objc.storeWeak
// CHECK: ret
func testWeakFieldStore(_ s: inout WeaksInAStructArc, _ obj: MYObject?) {
  s.myobj = obj
}

// Initializing a weak field uses objc_initWeak directly.
// CHECK-LABEL: define {{.*}} @"$s{{.*}}testWeakFieldInit
// CHECK: call ptr @llvm.objc.initWeak
// CHECK: ret
func testWeakFieldInit() -> WeaksInAStructArc {
  return WeaksInAStructArc(myobj: MYObject())
}

// Mixed struct field access at non-zero offset also uses objc_loadWeakRetained.
// CHECK-LABEL: define {{.*}} @"$s{{.*}}testMixedWeakFieldAccess
// CHECK: call ptr @llvm.objc.loadWeakRetained
// CHECK: ret
func testMixedWeakFieldAccess(_ s: MixedStrongWeakArc) -> MYObject? {
  return s.weak
}

// A __weak NSString * field is NOT bridged to String. It stays as NSString?
// and uses ObjC weak intrinsics, not swift_unknownObjectWeak* or bridging calls.
// CHECK-LABEL: define {{.*}} @"$s{{.*}}testWeakNSStringFieldAccess
// CHECK: call ptr @llvm.objc.loadWeakRetained
// CHECK-NOT: swift_bridgeObjectRetain
// CHECK-NOT: swift_unknownObjectWeak
// CHECK: ret
func testWeakNSStringFieldAccess(_ s: WeakNSStringArc) -> NSString? {
  return s.name
}

// Storing to a __weak NSString * field also uses ObjC weak intrinsics directly.
// CHECK-LABEL: define {{.*}} @"$s{{.*}}testWeakNSStringFieldStore
// CHECK: call ptr @llvm.objc.storeWeak
// CHECK-NOT: swift_unknownObjectWeak
// CHECK: ret
func testWeakNSStringFieldStore(_ s: inout WeakNSStringArc, _ str: NSString) {
  s.name = str
}

// Records with opaque weak arrays delegate lifecycle to Clang-synthesized
// helpers, which handle the hidden weak slots element-wise. The helper
// names encode the array (_AB<offset>s<size>n<count>_w<offset>_AE).
// CHECK-LABEL: define {{.*}} @"$s{{.*}}testCreateAndDestroyWeakArray
// CHECK: alloca %TSo12WeakArrayArcV
// CHECK: call void @__destructor_8_{{.*}}AB8s8n2_w8_AE
// CHECK: ret void
func testCreateAndDestroyWeakArray() {
  var s = WeakArrayArc()
  _ = s
}

// CHECK-LABEL: define {{.*}} @"$s{{.*}}testCopyWeakArray
// CHECK-SAME: ptr noalias sret(%TSo12WeakArrayArcV)
// CHECK-SAME: ptr noalias{{.*}}dereferenceable
// CHECK: call void @__copy_constructor_8_8_{{.*}}AB8s8n2_w8_AE
// CHECK-NOT: llvm.memcpy
// CHECK: ret void
func testCopyWeakArray(_ s: WeakArrayArc) -> WeakArrayArc {
  return s
}

// Assignment lowers directly to the Clang copy-assignment helper, which
// drives the hidden weak slots element-wise.
// CHECK-LABEL: define {{.*}} @"$s{{.*}}testWeakArrayAssign
// CHECK: call void @__copy_assignment_8_8_{{.*}}AB8s8n2_w8_AE
// CHECK: ret void
func testWeakArrayAssign(_ s: WeakArrayArc) -> WeakArrayArc {
  var d = WeakArrayArc()
  d = s
  return d
}

// A record combining weak and strong fixed-size arrays uses one
// Clang-synthesized helper covering both arrays.
// CHECK-LABEL: define {{.*}} @"$s{{.*}}testCopyMixedArrays
// CHECK-SAME: ptr noalias sret(%TSo19WeakStrongArraysArcV)
// CHECK-SAME: ptr noalias{{.*}}dereferenceable
// CHECK: call void @__copy_constructor_8_8_{{.*}}AB0s8n2_s0_AE{{.*}}AB16s8n2_w16_AE
// CHECK-NOT: llvm.memcpy
// CHECK: ret void
func testCopyMixedArrays(_ s: WeakStrongArraysArc) -> WeakStrongArraysArc {
  return s
}

// A record nesting a weak-array record delegates to the Clang helper for
// the nested type, which encodes the hidden array.
// CHECK-LABEL: define {{.*}} @"$s{{.*}}testCopyNestedWeakArray
// CHECK-SAME: ptr noalias sret(%TSo23OuterWithWeakArrayInnerV)
// CHECK-SAME: ptr noalias{{.*}}dereferenceable
// CHECK: call void @__copy_constructor_8_8_{{.*}}AB8s8n2_w8_AE
// CHECK-NOT: llvm.memcpy
// CHECK: ret void
func testCopyNestedWeakArray(_ s: OuterWithWeakArrayInner) -> OuterWithWeakArrayInner {
  return s
}

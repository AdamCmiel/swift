// RUN: %target-swift-frontend(mock-sdk: %clang-importer-sdk) -emit-silgen -enable-experimental-feature ImportCStructsWithArcFields %s | %FileCheck %s

// REQUIRES: objc_interop
// REQUIRES: swift_feature_ImportCStructsWithArcFields

import Foundation
import objc_structs

// A weak-field ARC struct should be address-only:
// @in_guaranteed for parameters, @out for returns, copy_addr for copies,
// struct_element_addr + load_weak for field access.

// CHECK-LABEL: sil hidden [ossa] @$s{{.*}}testCreateWeak
// CHECK: alloc_box ${ var WeaksInAStructArc }
// CHECK: apply {{%[0-9]+}}({{%[0-9]+}}, {{%[0-9]+}}) :
// CHECK-SAME: -> @out WeaksInAStructArc
// CHECK: destroy_addr
// CHECK: } // end sil function
func testCreateWeak() {
  var s = WeaksInAStructArc()
  _ = s
}

// CHECK-LABEL: sil hidden [ossa] @$s{{.*}}testCopyWeak
// CHECK: bb0(%0 : $*WeaksInAStructArc, %1 : $*WeaksInAStructArc):
// CHECK: copy_addr %1 to [init] %0
// CHECK: } // end sil function
func testCopyWeak(_ s: WeaksInAStructArc) -> WeaksInAStructArc {
  return s
}

// CHECK-LABEL: sil hidden [ossa] @$s{{.*}}testWeakFieldAccess
// CHECK: struct_element_addr %0, #WeaksInAStructArc.myobj
// CHECK: load_weak
// CHECK: } // end sil function
func testWeakFieldAccess(_ s: WeaksInAStructArc) -> MYObject? {
  return s.myobj
}

// A record with an opaque weak array is address-only: @out return,
// copy_addr for copies, destroy_addr for destruction.

// CHECK-LABEL: sil hidden [ossa] @$s{{.*}}testCreateWeakArray
// CHECK: apply {{%[0-9]+}}({{%[0-9]+}}, {{%[0-9]+}}) :
// CHECK-SAME: -> @out WeakArrayArc
// CHECK: destroy_addr
// CHECK: } // end sil function
func testCreateWeakArray() {
  var s = WeakArrayArc()
  _ = s
}

// CHECK-LABEL: sil hidden [ossa] @$s{{.*}}testCopyWeakArray
// CHECK: bb0(%0 : $*WeakArrayArc, %1 : $*WeakArrayArc):
// CHECK: copy_addr %1 to [init] %0
// CHECK: } // end sil function
func testCopyWeakArray(_ s: WeakArrayArc) -> WeakArrayArc {
  return s
}

// Visible fields of a record with an opaque weak array are accessed by
// address. The omitted array field has no projection.
// CHECK-LABEL: sil hidden [ossa] @$s{{.*}}testWeakArrayFieldAccess
// CHECK: struct_element_addr %0, #WeakArrayArc.tag
// CHECK: } // end sil function
func testWeakArrayFieldAccess(_ s: WeakArrayArc) -> Int32 {
  return s.tag
}

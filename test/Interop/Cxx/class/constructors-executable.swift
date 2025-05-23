// RUN: %target-run-simple-swift(-I %S/Inputs/ -Xfrontend -cxx-interoperability-mode=default -enable-experimental-feature CXXForeignReferenceTypeInitializers -Xfrontend -disable-availability-checking)
//
// REQUIRES: executable_test
// REQUIRES: swift_feature_CXXForeignReferenceTypeInitializers

import Constructors
import StdlibUnittest

var CxxConstructorTestSuite = TestSuite("CxxConstructors")

CxxConstructorTestSuite.test("ExplicitDefaultConstructor") {
  let instance = ExplicitDefaultConstructor()

  expectEqual(42, instance.x)
}

CxxConstructorTestSuite.test("ImplicitDefaultConstructor") {
  let instance = ImplicitDefaultConstructor()

  expectEqual(42, instance.x)
}

CxxConstructorTestSuite.test("DefaultedDefaultConstructor") {
  let instance = DefaultedDefaultConstructor()

  expectEqual(42, instance.x)
}

CxxConstructorTestSuite.test("MemberOfClassType") {
  let instance = MemberOfClassType()

  expectEqual(42, instance.member.x)
}

CxxConstructorTestSuite.test("ConstructorWithParam") {
  let instance = ConstructorWithParam(2)

  expectEqual(44, instance.x)
}

CxxConstructorTestSuite.test("TemplatedConstructor") {
  let arg = ArgType(i: 2)
  let instance = TemplatedConstructor(arg)

  expectEqual(2, instance.value.i)
}

CxxConstructorTestSuite.test("implicit default ctor") {
  // Make sure that fields of C++ structs are zeroed out.

  let instance1 = ConstructorWithParam()
  expectEqual(0, instance1.x)

  let instance2 = IntWrapper()
  expectEqual(0, instance2.x)

  // CopyAndMoveConstructor is not default-initializable in C++, however, Swift
  // generates an implicit deprecated default constructor for C++ structs for
  // compatibility with C. This constructor will zero out the entire backing
  // memory of the struct, including fields that have an init expression.
  // See `SwiftDeclSynthesizer::createDefaultConstructor`.
  let instance3 = CopyAndMoveConstructor()
  expectEqual(0, instance3.value)
  expectNil(instance3.ptr)
}

CxxConstructorTestSuite.test("MoveConstructorWithOneParamWithDefaultArg") {
  let instance1 = MoveConstructorWithOneParameterWithDefaultArg(5)
  let instance2 = instance1
  let instance3 = MoveConstructorWithOneParameterWithDefaultArg(5)
  expectTrue(instance2.value + instance3.value >= 10)
}

CxxConstructorTestSuite.test("ImportStaticFactoryAsInitializer") {
  let x = UserFactoriesForCXXRefTypeInit.ImportWithCtor()
  expectEqual(x.param1, 0)
  expectEqual(x.param2, 0)
  let y = x
  let z = UserFactoriesForCXXRefTypeInit.ImportWithCtor(1)
  expectEqual(z.param1, 1)
  expectEqual(z.param2, 0)
  let z2 = UserFactoriesForCXXRefTypeInit.ImportWithCtor(2, 3)
  expectEqual(z2.param1, 2)
  expectEqual(z2.param2, 3)
  let z3 = UserFactoriesForCXXRefTypeInit.ImportWithCtor(2, 3, 4)
  expectEqual(z3.param1, 2)
  expectEqual(z3.param2, 3)
  let v = UserFactoriesForCXXRefTypeInit.Value(x: 2)
  expectEqual(v.getX(), 2)
}

CxxConstructorTestSuite.test("SynthesizeAndImportStaticFactoryAsInitializer") {
  let x1 = SwiftInitSynthesisForCXXRefTypes.CompilerGeneratedDefaultCtor()
  expectEqual(x1.val, 1)
  x1.val = 2
  expectEqual(x1.val, 2)

  let x2 = SwiftInitSynthesisForCXXRefTypes.ExplicitCompilerGeneratedDefaultCtor()
  expectEqual(x2.val, 1)
  x2.val = 2
  expectEqual(x2.val, 2)

  let x3 = SwiftInitSynthesisForCXXRefTypes.ImmortalReference()
  expectEqual(x3.val, 1)
  x3.val = 2
  expectEqual(x3.val, 2)

  let x4 = SwiftInitSynthesisForCXXRefTypes.UserProvidedDefaultCtor()
  expectEqual(x4.val, 2)

  let x5 = SwiftInitSynthesisForCXXRefTypes.UserProvidedStaticFactory()
  expectEqual(x5.val, 2)

  let x6 = SwiftInitSynthesisForCXXRefTypes.UserProvidedStaticFactory(3)
  expectEqual(x6.val, 3)
}

runAllTests()

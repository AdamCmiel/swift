@import Foundation;

struct StructOfNSStrings {
  __unsafe_unretained NSString *nsstr;
};

struct StructOfBlocks {
  void (^__unsafe_unretained _Nonnull block)(void);
};

@interface MYObject: NSObject
@end

struct StrongsInAStruct {
  __strong MYObject *myobj;
};

struct WeaksInAStruct {
  __weak MYObject *myobj;
};

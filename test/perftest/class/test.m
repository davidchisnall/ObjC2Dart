#import <Foundation/Foundation.h>

@interface MyClass : NSObject

- (void)method;

@end

@implementation MyClass

- (void)method {
}

@end

void test(int n) {
	MyClass *o = [[MyClass alloc] init];
	for (int i = 0; i < n; ++i) {
		[o method];
	}
}

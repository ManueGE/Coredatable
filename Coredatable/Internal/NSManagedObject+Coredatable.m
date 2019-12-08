//
//  NSManagedObject+Coredatable.m
//  Coredatable
//
//  Created by Manu on 07/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

#import "NSManagedObject+Coredatable.h"
#import <Coredatable/Coredatable-Swift.h>

@implementation NSManagedObject (Coredatable)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype) initWithDecodingContext:(id<DecodingContextType>)decodingContext error:(NSError * _Nullable __autoreleasing *)error {
    NSManagedObjectContext * context = decodingContext.managedObjectContext;
    if (self = [self initWithContext:context]) {
        NSArray * properties = self.entity.properties;
        for (NSPropertyDescription * property in properties) {
            NSString * propertyName = property.name;
            if ([decodingContext containsKey:propertyName]) {
                NSObject * value = [decodingContext decodedValueForKey:propertyName];
                [self setValue:value forKey:propertyName];
            }
        }
    }
    return self;
}
#pragma clang diagnostic pop
@end


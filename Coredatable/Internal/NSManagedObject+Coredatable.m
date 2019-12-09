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
- (instancetype) initWithAnotherManagedObject:(NSManagedObject *)managedObject {
    return managedObject;
}
#pragma clang diagnostic pop
@end


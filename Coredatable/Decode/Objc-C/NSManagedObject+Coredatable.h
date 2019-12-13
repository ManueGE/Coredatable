//
//  NSManagedObject+Coredatable.h
//  Coredatable
//
//  Created by Manu on 07/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

#import <CoreData/CoreData.h>
@protocol DecodingContextType;

NS_ASSUME_NONNULL_BEGIN

@interface NSManagedObject (Coredatable)
/// This is just a little trick to be able to call this init from another swift init. It will just return the object passed
- (instancetype) initWithAnotherManagedObject:(NSManagedObject *) managedObject;
@end

NS_ASSUME_NONNULL_END

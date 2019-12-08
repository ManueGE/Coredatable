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
- (nullable instancetype) initWithDecodingContext:(id<DecodingContextType>) decodingContext error:(NSError * __nullable * __nullable)error;
@end

NS_ASSUME_NONNULL_END

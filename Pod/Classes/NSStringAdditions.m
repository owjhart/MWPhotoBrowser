//
//  NSStringAdditions.m
//  Pods
//
//  Created by Luciano Sugiura on 28/01/16.
//
//

#import "NSStringAdditions.h"

@implementation NSString (Additions)

- (NSString *)base64
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64EncodedStringWithOptions:0];
}

@end

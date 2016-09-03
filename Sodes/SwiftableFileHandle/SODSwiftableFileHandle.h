//
//  SODSwiftableFileHandle.h
//  SwiftableFileHandle
//
//  Created by Jared Sinclair on 8/6/16.
//
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface SODSwiftableFileHandle : NSObject

- (nullable instancetype)initWithUrl:(NSURL *)fileUrl;

- (BOOL)writeData:(NSData *)data at:(unsigned long long)location error:(NSError **)error;

- (nullable NSData *)readDataFromLocation:(unsigned long long)location length:(unsigned long long)length error:(NSError **)error;

- (void)synchronizeFile;
- (void)closeFile;

@end

NS_ASSUME_NONNULL_END

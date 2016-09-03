//
//  SODSwiftableFileHandle.m
//  SwiftableFileHandle
//
//  Created by Jared Sinclair on 8/6/16.
//
//

#import "SODSwiftableFileHandle.h"

@interface SODSwiftableFileHandle()

@property (nonatomic, assign) BOOL isClosed;
@property (nonatomic, readonly) NSFileHandle *handle;
@property (nonatomic, readonly) NSLock *lock;

@end

@implementation SODSwiftableFileHandle

@synthesize isClosed = _isClosed;

- (nullable instancetype)initWithUrl:(NSURL *)fileUrl {
    NSError *error = nil;
    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingURL:fileUrl error:&error];
    if (error != nil || handle == nil) {
        NSLog(@"[SODSwiftableFileHandle initWithUrl:]: Unable to initialize because of error: %@", error);
        return nil;
    }
    self = [super init];
    if (self) {
        _handle = handle;
        _lock = [NSLock new];
    }
    return self;
}

- (BOOL)writeData:(NSData *)data at:(unsigned long long)location error:( NSError * _Nullable *)error {
    
    if (self.isClosed) { return NO; }
    
    BOOL successful;
    [self.lock lock];
    @try {
        [self.handle seekToFileOffset:location];
        [self.handle writeData:data];
        [self.handle synchronizeFile];
        successful = YES;
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:exception.name code:10001 userInfo:exception.userInfo];
        successful = NO;
    } @finally {
        // no op
    }
    [self.lock unlock];
    
    return successful;
}

- (nullable NSData *)readDataFromLocation:(unsigned long long)location length:(unsigned long long)length error:(NSError * _Nullable __autoreleasing *)error {
    
    if (self.isClosed) { return nil; }
    
    NSData *data = nil;
    [self.lock lock];
    @try {
        [self.handle seekToFileOffset:location];
        NSData *readData = [self.handle readDataOfLength:(NSUInteger)length];
        if (readData.length == length) {
            data = readData;
        }
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:exception.name code:10001 userInfo:exception.userInfo];
    } @finally {
        // no op
    }
    [self.lock unlock];
    
    return data;
}

- (void)synchronizeFile {
    if (self.isClosed) { return; }
    @try {
        [self.handle synchronizeFile];
    } @catch (NSException *exception) {
        NSLog(@"SODSwiftableFileHandle.synchronizeFile: %@", exception);
    } @finally {
        //
    }
}

- (void)closeFile {
    if (self.isClosed) { return; }
    @try {
        [self.handle closeFile];
    } @catch (NSException *exception) {
        NSLog(@"SODSwiftableFileHandle.closeFile: %@", exception);
    } @finally {
        //
    }
}

- (BOOL)isClosed {
    BOOL value;
    [self.lock lock];
    value = _isClosed;
    [self.lock unlock];
    return value;
}

- (void)setIsClosed:(BOOL)isClosed {
    [self.lock lock];
    _isClosed = isClosed;
    [self.lock unlock];
}

@end

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTDefaultFileStorage.h"

@interface OCTDefaultFileStorage ()

@property (copy, nonatomic) NSString *saveFileName;
@property (copy, nonatomic) NSString *baseDirectory;
@property (copy, nonatomic) NSString *temporaryDirectory;

@end

@implementation OCTDefaultFileStorage

#pragma mark -  Lifecycle

- (instancetype)initWithBaseDirectory:(NSString *)baseDirectory temporaryDirectory:(NSString *)temporaryDirectory
{
    return [self initWithToxSaveFileName:nil baseDirectory:baseDirectory temporaryDirectory:temporaryDirectory];
}

- (instancetype)initWithToxSaveFileName:(NSString *)saveFileName
                          baseDirectory:(NSString *)baseDirectory
                     temporaryDirectory:(NSString *)temporaryDirectory
{
    self = [super init];

    if (! self) {
        return nil;
    }

    if (! saveFileName) {
        saveFileName = @"save";
    }

    self.saveFileName = [saveFileName stringByAppendingString:@".tox"];
    self.baseDirectory = baseDirectory;
    self.temporaryDirectory = temporaryDirectory;

    return self;
}

#pragma mark -  OCTFileStorageProtocol

- (NSString *)pathForToxSaveFile
{
    return [self.baseDirectory stringByAppendingPathComponent:self.saveFileName];
}

- (NSString *)pathForDatabase
{
    return [self.baseDirectory stringByAppendingPathComponent:@"database"];
}

- (NSString *)pathForDatabaseEncryptionKey
{
    return [self.baseDirectory stringByAppendingPathComponent:@"database.encryptionkey"];
}

- (NSString *)pathForDownloadedFilesDirectory
{
    return [self.baseDirectory stringByAppendingPathComponent:@"files"];
}

- (NSString *)pathForUploadedFilesDirectory
{
    return [self.baseDirectory stringByAppendingPathComponent:@"files"];
}

- (NSString *)pathForTemporaryFilesDirectory
{
    return self.temporaryDirectory;
}

@end

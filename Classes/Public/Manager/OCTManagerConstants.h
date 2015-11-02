//
//  OCTManagerConstants.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

typedef NS_ENUM(NSInteger, OCTFetchRequestType) {
    OCTFetchRequestTypeFriend,
    OCTFetchRequestTypeFriendRequest,
    OCTFetchRequestTypeChat,
    OCTFetchRequestTypeMessageAbstract,
};

typedef NS_ENUM(NSInteger, OCTMessageFileType) {
    /**
     * File is incoming and is waiting confirmation of user to be downloaded.
     * Please start loading or cancel it with <<placeholder>> method.
     */
    OCTMessageFileTypeWaitingConfirmation,

    /**
     * File is downloading or uploading.
     */
    OCTMessageFileTypeLoading,

    /**
     * Downloading or uploading of file is paused.
     */
    OCTMessageFileTypePaused,

    /**
     * Downloading or uploading of file was canceled.
     */
    OCTMessageFileTypeCanceled,

    /**
     * File is fully loaded.
     * In case of incoming file now it can be shown to user.
     */
    OCTMessageFileTypeReady,
};

extern NSString *const kOCTManagerErrorDomain;

typedef NS_ENUM(NSInteger, OCTManagerInitError) {
    /**
     * Cannot create symmetric key from given passphrase.
     */
    OCTManagerInitErrorPassphraseFailed,

    /** ---------------------------------------- */

    /**
     * Cannot copy tox save at `importToxSaveFromPath` path.
     */
    OCTManagerInitErrorCannotImportToxSave,

    /** ---------------------------------------- */

    /**
     * Cannot decrypt tox save file.
     * Some input data was empty.
     */
    OCTManagerInitErrorDecryptNull,

    /**
     * Cannot decrypt tox save file.
     * The input data is missing the magic number (i.e. wasn't created by this module, or is corrupted).
     */
    OCTManagerInitErrorDecryptBadFormat,

    /**
     * Cannot decrypt tox save file.
     * The encrypted byte array could not be decrypted. Either the data was corrupt or the password/key was incorrect.
     */
    OCTManagerInitErrorDecryptFailed,

    /** ---------------------------------------- */

    /**
     * Cannot create tox.
     * Unknown error occurred.
     */
    OCTManagerInitErrorCreateToxUnknown,

    /**
     * Cannot create tox.
     * Was unable to allocate enough memory to store the internal structures for the Tox object.
     */
    OCTManagerInitErrorCreateToxMemoryError,

    /**
     * Cannot create tox.
     * Was unable to bind to a port. This may mean that all ports have already been bound,
     * e.g. by other Tox instances, or it may mean a permission error.
     */
    OCTManagerInitErrorCreateToxPortAlloc,

    /**
     * Cannot create tox.
     * proxyType was invalid.
     */
    OCTManagerInitErrorCreateToxProxyBadType,

    /**
     * Cannot create tox.
     * proxyAddress had an invalid format or was nil (while proxyType was set).
     */
    OCTManagerInitErrorCreateToxProxyBadHost,

    /**
     * Cannot create tox.
     * proxyPort was invalid.
     */
    OCTManagerInitErrorCreateToxProxyBadPort,

    /**
     * Cannot create tox.
     * The proxy host passed could not be resolved.
     */
    OCTManagerInitErrorCreateToxProxyNotFound,

    /**
     * Cannot create tox.
     * The saved data to be loaded contained an encrypted save.
     */
    OCTManagerInitErrorCreateToxEncrypted,

    /**
     * Cannot create tox.
     * The data format was invalid. This can happen when loading data that was
     * saved by an older version of Tox, or when the data has been corrupted.
     * When loading from badly formatted data, some data may have been loaded,
     * and the rest is discarded. Passing an invalid length parameter also
     * causes this error.
     */
    OCTManagerInitErrorCreateToxBadFormat,
};

typedef NS_ENUM(NSInteger, OCTDNSError) {
    /**
     * Given string for DNS discovery is wrong.
     */
    OCTDNSErrorWrongString,

    /**
     * No public key is found for domain. You have to add server first with `addTox3Server:publicKey:` method.
     *
     * This error can occur only in tox3 dns discovery method.
     */
    OCTDNSErrorNoPublicKey,

    /**
     * Error occurred during dns discovery.
     */
    OCTDNSErrorDNSQueryError,
};

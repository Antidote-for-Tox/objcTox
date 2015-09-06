//
//  OCTToxEncryptSaveConstants.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 05/09/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

typedef NS_ENUM(NSUInteger, OCTToxEncryptSaveKeyDerivationError) {
    OCTToxEncryptSaveKeyDerivationErrorNone,
    OCTToxEncryptSaveKeyDerivationErrorFailed,
};

typedef NS_ENUM(NSUInteger, OCTToxEncryptSaveEncryptionError) {
    OCTToxEncryptSaveEncryptionErrorNone,

    /**
     * Some input data was empty.
     */
    OCTToxEncryptSaveEncryptionErrorNull,

    /**
     * Encryption failed.
     */
    OCTToxEncryptSaveEncryptionErrorFailed,
};

typedef NS_ENUM(NSUInteger, OCTToxEncryptSaveDecryptionError) {
    OCTToxEncryptSaveDecryptionErrorNone,

    /**
     * Some input data was empty.
     */
    OCTToxEncryptSaveDecryptionErrorNull,

    /**
     * The input data is missing the magic number (i.e. wasn't created by this module, or is corrupted).
     */
    OCTToxEncryptSaveDecryptionErrorBadFormat,

    /**
     * The encrypted byte array could not be decrypted. Either the data was corrupt or the password/key was incorrect.
     */
    OCTToxEncryptSaveDecryptionErrorFailed,
};

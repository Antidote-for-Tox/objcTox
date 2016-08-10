# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased][unreleased]
### Added
- OS X platform in podspec.
- Retrying sending file transfers.
- removeMessages: method.
- Realm database encryption.

### Changes
- Realm updated to version 1.0.1.
- RBQFetchedResultsController removed. Use RLMResults with `addNotificationBlock:` method insted.
- OCTSubmanagerFiles: using original file names instead of generated ones.
- OCTSubmanagerChats: replacing removeChatWithAllMessages: method with removeAllMessagesInChat:removeChat:
- OCTDefaultFileStorage: storing all upload and download files in single "files" directory.
- OCTManager: manager is now created asynchronously.

## [0.6.0] - 2016-03-27
### Added
- File transfers.
- Avatars.

### Changes
- Bootstrap nodes updated and moved to separate json file.
- Realm updated to version 0.98.5.
- Killing all active calls when killing toxav.

### Fixes
- Bug with switching to wrong camera on iOS.
- Crash when killing OCTManager [#154](https://github.com/Antidote-for-Tox/objcTox/issues/154).

## [0.5.0] - 2016-02-12
### Added
- install.sh script.
- OS X Demo.

### Changes
- Updating toxcore to 0.0.1-94cc8b1.
- Splitting calls API for Mac and iOS.
- Change video quality to default medium.
- Making code more swift friendly.

### Fixes
- Some refactoring.
- Bug with last seen date not updated.
- Lots of issues in audio and video calls.

## [0.4.0] - 2015-11-03
### Added
- Audio and video calls.

### Changes
- toxcore was updated to 0.0.1-542338a.
- OCTSubmanagerUser: delegate method renamed from OCTSubmanagerUser:connectionStatusUpdate: to submanagerUser:connectionStatusUpdate:

### Fixes
- Build issue on Xcode 7.
- Call tox_iterate_interval after every tox_iterate.

## [0.3.0] - 2015-09-22
### Added
- OCTToxEncryptSave, wrapper for toxencryptsave.
- OCTManager: added encrypted tox files support.
- OCTManager: added `configuration` method.
- OCTManager: added `isToxSaveEncryptedAtPath` method.

### Changed
- Realm updated to version 0.95.0.
- toxcore was updated to 0.0.0-2ab3b14-2.
- OCTSettingsStorageProtocol was removed. Now objcTox stores its settings in Realm database.
- OCTManager: `initWithConfiguration:error` method now uses OCTManagerInitError codes.

### Deprecated
- `[OCTManager initWithConfiguration:loadToxSaveFilePath:error:]`, use `[OCTManager initWithConfiguration:error:]` instead. Instead of `toxSaveFilePath` use property on OCTManagerConfiguration: `importToxSaveFromPath`.

## [0.2.1] - 2015-08-30
### Fixed
- Bootstrapping was using same nodes over and over again.
- Memory issues with OCTSubmanagerBootstrap.
- Realm migration crash when recreating OCTManager with same configuration.
- Crash when exporting profile from OCTManager.
- Adding all unadded friends to Realm on startup (this may happen when importing existing .tox file).
- Changing friend's nickname to default one when setting nil or empty string.

## [0.2.0] - 2015-08-22
### Added
- OS X 10.9+ compatibility
- OCTSubmanagerBootstrap that implements bootstrapping logic from STS [Tox-STS/#65](https://github.com/Tox/Tox-STS/pull/65/files).
- OCTToxDNS which is wrapper for toxdns.
- OCTSubmanagerDNS with methods for tox3 and tox1 discovery.
- Predefined list of nodes to bootstrap from https://wiki.tox.chat/users/nodes.

### Changed
- `toxcore-ios` replaced with `toxcore` pod.
- RBQFetchedResultsController pod replaced with integrated-one with fixes for OS X compatibility. **Note** that NSFetchedResultsChangeType was replaced with RBQFetchedResultsChangeType.
- OCTSubmanagerFriends: removed return `BOOL` value from `removeFriendRequest:` method.
- Removed RBQFetchedResultsController logging.

### Fixed
- Crash when loading bad profile [#98](https://github.com/Antidote-for-Tox/objcTox/issues/98).
- Friend request was added several times [#50](https://github.com/Antidote-for-Tox/objcTox/issues/50).

### Deprecated
- `[OCTManager initWithConfiguration:]`, use `[OCTManager initWithConfiguration:error:]` instead.
- `[OCTManager initWithConfiguration:loadToxSaveFilePath:]`, use `[OCTManager initWithConfiguration:loadToxSaveFilePath:error:]` instead.
- `[OCTManager bootstrapFromHost:port:publicKey:error:]`, use OCTSubmanagerBootstrap instead.
- `[OCTManager addTCPRelayWithHost:port:publicKey:error:]`, use OCTSubmanagerBootstrap instead.

## [0.1.0] - 2015-06-30
### Added
- OCTTox wrapper for tox.h file.
- OCTManager that provides high level API for Tox. Below are features for OCTManager.
- Changing user name, status, status message, nospam.
- Sending, receiving, removing and accepting friend requests.
- Removing friends.
- Auto updating and changeable nickname for friend.
- Chat objects with various information.
- Sending and receiving messages.

[unreleased]: https://github.com/Antidote-for-Tox/objcTox/compare/0.6.0...master
[0.6.0]: https://github.com/Antidote-for-Tox/objcTox/compare/0.5.0...0.6.0
[0.5.0]: https://github.com/Antidote-for-Tox/objcTox/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/Antidote-for-Tox/objcTox/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/Antidote-for-Tox/objcTox/compare/0.2.1...0.3.0
[0.2.1]: https://github.com/Antidote-for-Tox/objcTox/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/Antidote-for-Tox/objcTox/compare/0.1.0...0.2.0

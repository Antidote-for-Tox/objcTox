[![Circle CI](https://circleci.com/gh/Antidote-for-Tox/objcTox/tree/master.svg?style=svg)](https://circleci.com/gh/Antidote-for-Tox/objcTox/tree/master) [![codecov.io](http://codecov.io/github/Antidote-for-Tox/objcTox/coverage.svg?branch=master)](http://codecov.io/github/Antidote-for-Tox/objcTox?branch=master)

# objcTox

Objective-C wrapper for [Tox](https://tox.chat/).

## Features

See [CHANGELOG](CHANGELOG.md) for list of notable changes (unreleased, current and previous versions).

- iOS 7.0+ and OS X 10.9+ compatibility.
- OCTTox wrapper for tox.h file.
- OCTToxDNS wrapper for toxdns.h file.
- OCTManager that provides high level API for Tox.

##### OCTManager features

- Bootstrapping logic from STS.
- Changing user name, status, status message, nospam.
- Sending, receiving, removing and accepting friend requests.
- Removing friends.
- Auto-updated and changeable nickname for friend.
- Chat objects with various information.
- Sending and receiving messages.
- tox1 and tox3 DNS discovery.

#### What's next?

- [**Now**](https://github.com/Antidote-for-Tox/objcTox/milestones/Now) - this milestone has issues that will go to the next release.
- [**Next**](https://github.com/Antidote-for-Tox/objcTox/milestones/Next) - stuff we'll probably do soon.
- [**Faraway**](https://github.com/Antidote-for-Tox/objcTox/milestones/Faraway) - stuff we'll probably *won't* do soon.

Also there may be other [milestones](https://github.com/Antidote-for-Tox/objcTox/milestones) that represent long-running and big ongoing tasks.

## Installation

objcTox is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "objcTox"

## Downloads

1. Clone repo `git clone https://github.com/Antidote-for-Tox/objcTox.git`
2. Install CocoaPods `pod install`
3. Open `objcTox.xcworkspace` file with Xcode 7.

Cocoapods 0.38.X for some reason is failing with

```
[!] The 'Pods-iOSDemo' target has frameworks with conflicting names: vpx.
```

While it [isn't resolved](https://github.com/Antidote-for-Tox/objcTox/issues/117) you can use oldest version of Cocoapods:

- install it with `sudo gem install cocoapods -v 0.37.2`
- run by adding version number after `pod` work: `pod _0.37.2_ install`
- if you like you can remove newest versions of Cocoapods at all: `gem uninstall cocoapods -v '>0.37.2' --force`

## Contribution

Before contributing please check [style guide](objective-c-style-guide.md).

objcTox is using [Uncrustify](http://uncrustify.sourceforge.net/) code beautifier. Before creating pull request please run it.

You can install it with [Homebrew](http://brew.sh/):

```
brew install uncrustify
```

After installing you can:

- check if there are any formatting issues with

```
./run-uncrustify.sh --check
```

- apply uncrustify to all sources with

```
./run-uncrustify.sh --apply
```

There is also git `pre-commit` hook. On committing if there are any it will gently propose you a patch to fix them. To install hook run

```
ln -s ../../pre-commit.sh .git/hooks/pre-commit
```

## Author

Dmytro Vorobiov, d@dvor.me

## License

objcTox is available under the MIT license. See the [LICENSE](LICENSE) file for more info.


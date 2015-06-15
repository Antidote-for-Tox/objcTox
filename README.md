[![Build Status](https://img.shields.io/travis/Antidote-for-Tox/objcTox/master.svg?style=flat)](https://travis-ci.org/Antidote-for-Tox/objcTox) [![Coverage Status](https://coveralls.io/repos/Antidote-for-Tox/objcTox/badge.svg)](https://coveralls.io/r/Antidote-for-Tox/objcTox)

# objcTox

Objective-C wrapper for [Tox](https://tox.im/).

Description will be here soon. :)

## Downloads

1. Clone repo `git clone --recursive https://github.com/Antidote-for-Tox/objcTox.git`
2. Install CocoaPods `pod install`
3. Open `objcTox.xcworkspace` file with Xcode 5+.

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


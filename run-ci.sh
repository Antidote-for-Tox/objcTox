#!/bin/bash

case $1 in
    iOS)
        xctool -workspace objcTox.xcworkspace -scheme iOSDemo -sdk iphonesimulator CODE_SIGNING_REQUIRED=NO GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES clean test
    ;;

    macOS)
        xctool -workspace objcTox.xcworkspace -scheme OSXDemo -sdk macosx10.11 CODE_SIGNING_REQUIRED=NO clean test
    ;;

    uncrustify)
        ./run-uncrustify.sh --check
    ;;

    *)
        echo "Unknown option"
        exit 1
    ;;
esac

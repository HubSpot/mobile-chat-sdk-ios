# Contributing

These are notes for anyone working on the SDK itself - if you are just looking to integrate the sdk , see README.md

## Public Header Documentation

Github actions is used to build a copy of the documentation from doc comments, and its hosted here: https://tapadoo.github.io/hubspot-mobile-sdk-ios/documentation/hubspotmobilesdk

## Developer dependencies

### Build Tools

SDK development environment is assumed to be using Xcode 15

### Formatting with Swiftformat

The `Makefile` tasks for formatting use [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) , which it assumes is available. It's not added as a dependency to the SDK itself as its optional and only used during development, not shipped with the SDK.


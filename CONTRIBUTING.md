# Contributing

These are notes for anyone working on the SDK itself - if you are just looking to integrate the SDK, see README.md

## Developer dependencies

### Build Tools

SDK development environment is assumed to be using Xcode 15

### Formatting with SwiftFormat

The `Makefile` tasks for formatting use [SwiftFormat](https://github.com/nicklockwood/SwiftFormat), which it assumes is available. It's not added as a dependency to the SDK itself as it's optional and only used during development, not shipped with the SDK.


# Changelog

All notable changes to this project are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-07-22

### Added

- Added strict Flutter linting and automated CI checks.
- Added regression tests for conversions, parsing, mixing, and contrast.
- Added correctly spelled `ensureContrast`, `ensureLightContrast`,
  `ensureDarkContrast`, and `withCyan` APIs.
- Added value equality to `WideColor` and `CMYKColor`.
- Added support for three-, four-, six-, and eight-digit hexadecimal colors.

### Changed

- Updated the minimum supported versions to Dart 3.8 and Flutter 3.27.
- Changed hexadecimal output to padded uppercase AARRGGBB format.
- Changed `WideColor.withAlpha` to return an immutable `WideColor`.
- Improved package metadata, documentation, and examples.
- Replaced deprecated Flutter color component accessors.

### Fixed

- Fixed CMYK conversion and interpolation calculations.
- Fixed magenta updates changing the yellow component.
- Fixed HSL transformations using HSV saturation.
- Fixed light contrast adjustment delegating to the dark adjustment path.
- Fixed contrast ratios when ARGB ordering differed from luminance ordering.
- Fixed six-digit hexadecimal input producing fully transparent colors.

### Deprecated

- Deprecated misspelled compatibility aliases beginning with `asure`.
- Deprecated `withcyan`, `withMagetna`, and `bit` compatibility aliases.

## [1.0.3+2] - 2024-08-19

### Changed

- Applied minor formatting changes.

## [1.0.2+2] - 2024-08-19

### Fixed

- Patched an error in `CMYKColor.lerp`.
- Corrected `cian` to `cyan` across the public API.

### Changed

- Added the `@immutable` annotation to `CMYKColor`.

## [1.0.1+1] - 2024-07-16

- Initial release.

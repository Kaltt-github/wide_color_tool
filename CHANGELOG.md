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
- Added `maxBit` and `percentageToBit` for explicit 8-bit channel conversion.
- Added an optional hexadecimal prefix to `WideColor.toString` and
  `ToolColor.toString`.
- Added `hueDegrees` for precise, non-truncated hue access while preserving the
  integer `hue` API.
- Added complete public API documentation and GitHub issue/PR templates.
- Added an enforced 100% line-coverage threshold and boundary-condition tests
  to CI.

### Changed

- Updated the minimum supported versions to Dart 3.8 and Flutter 3.27.
- Changed hexadecimal output to padded uppercase AARRGGBB format.
- Changed `WideColor.withAlpha` to return an immutable `WideColor`.
- Improved package metadata, documentation, and examples.
- Moved platform runners into a standalone application under `example/`.
- Replaced deprecated Flutter color component accessors.

### Fixed

- Fixed CMYK conversion and interpolation calculations.
- Fixed magenta updates changing the yellow component.
- Fixed HSL transformations using HSV saturation.
- Fixed light contrast adjustment delegating to the dark adjustment path.
- Fixed contrast ratios when ARGB ordering differed from luminance ordering.
- Fixed six-digit hexadecimal input producing fully transparent colors.
- Fixed `toString()` duplicating the default `#` hexadecimal prefix.
- Fixed CMYK constructor assertions checking only the lower channel bounds.
- Fixed fractional hue truncation changing RGB values during HSV/HSL
  conversions and endpoint mixing.

### Removed

- Removed the misspelled `asureContrast`, `asureLightContrast`, and
  `asureDarkContrast` methods. Use their corresponding `ensure` methods.
- Removed `withcyan`; use `withCyan`.
- Removed `withMagetna`; use `withMagenta`.
- Removed `bit`; use `maxBit`.

These removals are intentionally part of the `2.0.0` major-version migration.
They were not removed from a stable `2.x` release because `2.0.0` had not yet
been published.

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

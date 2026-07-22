# wide_color_tool

[![CI](https://github.com/Kaltt-github/wide_color_tool/actions/workflows/ci.yml/badge.svg)](https://github.com/Kaltt-github/wide_color_tool/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A focused Flutter library for creating, converting, mixing, and comparing colors
across RGB, HSV, HSL, and CMYK color spaces. It also includes relative
luminance and WCAG contrast utilities.

## Features

- Immutable `WideColor` and mutable `ToolColor` APIs
- RGB, HSV, HSL, and CMYK conversions
- Color mixing in any supported color space
- WCAG relative luminance and contrast-ratio calculations
- Automatic light or dark contrast adjustment
- RGB, ARGB, RRGGBB, and AARRGGBB hexadecimal parsing
- Alpha and opacity manipulation

## Requirements

- Dart 3.8 or later
- Flutter 3.27 or later

## Migrating from 1.x

Version 2.0 removes misspelled legacy APIs instead of carrying them into the
new major release:

| Removed API | Replacement |
| --- | --- |
| `bit` | `maxBit` |
| `withcyan` | `withCyan` |
| `withMagetna` | `withMagenta` |
| `asureContrast` | `ensureContrast` |
| `asureLightContrast` | `ensureLightContrast` |
| `asureDarkContrast` | `ensureDarkContrast` |

Hexadecimal strings are now rendered as uppercase AARRGGBB. `toString()` uses
`#` by default and accepts a custom prefix, such as `color.toString('0x')`.

## Installation

Add the package to your project:

```sh
flutter pub add wide_color_tool
```

Then import it:

```dart
import 'package:wide_color_tool/wide_color_tool.dart';
```

## Usage

### Create and convert colors

```dart
final red = WideColor.fromRGB(255, 0, 0);
final green = WideColor.fromHSV(120, 1, 1);
final blue = WideColor.fromHSL(240, 1, 0.5);
final cyan = WideColor.fromCMYK(1, 0, 0, 0);
final magenta = WideColor.fromString('#FF00FF');

print(red.hsv);
print(green.hsl);
print(blue.cmyk);
print(cyan.color);
print(magenta.string); // #FFFF00FF (AARRGGBB)
```

Six-digit hexadecimal values are treated as opaque RRGGBB colors. Eight-digit
values use Flutter's AARRGGBB channel order.

### Transform and mix colors

```dart
final color = WideColor.fromRGB(100, 150, 200);

final lighter = color.withLight(0.8);
final saturated = color.withSaturationV(0.9);
final redder = color.withRed(220);
final mixed = color.mix(
  WideColor.fromRGB(200, 100, 50),
  otherInfluence: 0.3,
  source: ColorSource.rgb,
);
```

Every `WideColor` transformation returns a new immutable value. Use `ToolColor`
when in-place updates are more convenient:

```dart
final editable = ToolColor.fromString('#336699');
editable.red = 128;
editable.opacity = 0.8;
```

### Measure and improve contrast

```dart
final background = WideColor.fromRGB(240, 240, 240);
final text = WideColor.fromRGB(150, 150, 150);

final ratio = background.contrast(text);
final accessibleText = background.fixContrast(
  text,
  minContrast: 4.5,
  preference: ContrastPreference.dark,
);
```

The adjustment returns the closest reachable color in the requested direction.
If the target ratio cannot be reached, it returns the corresponding black or
white endpoint.

## Development

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --coverage
dart run tool/check_coverage.dart 80
```

Run the independent example application separately:

```sh
cd example
flutter pub get
flutter run
```

See [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a change. Security
issues should follow the private process in [SECURITY.md](SECURITY.md).
The generated API reference is published on
[pub.dev](https://pub.dev/documentation/wide_color_tool/latest/). The release
checklist and publication commands are documented in [RELEASING.md](RELEASING.md).

## License

Released under the [MIT License](LICENSE).

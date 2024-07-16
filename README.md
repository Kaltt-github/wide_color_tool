# wide_color_tool

A comprehensive color manipulation library for Flutter, providing extensive functionality for working with colors in various color spaces.

## Features

- Support for multiple color spaces: RGB, HSV, HSL, and CMYK
- Easy conversion between color spaces
- Color mixing and blending
- Contrast calculation and adjustment
- Luminance calculation
- Opacity and alpha channel manipulation
- Flexible color creation methods

## Getting Started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  wide_color: ^1.0.1
```

Then run:
`flutter pub get`

**Usage**
**Creating Colors**
```dart
final red = WideColor.fromRGB(255, 0, 0);

final green = WideColor.fromHSV(120, 1.0, 1.0);

final blue = WideColor.fromHSL(240, 1.0, 0.5);

final yellow = WideColor.fromCMYK(0.0, 1.0, 1.0, 0.0);

final magenta = WideColor.fromString("#FF00FF");
```

**Color Space Conversions**
```dart
final purple = WideColor.fromRGB(128, 0, 128);

print(purple.hsv);  // HSVColor
print(purple.hsl);  // HSLColor
print(purple.cmyk);  // CMYKColor
```

**Color Manipulation**
```dart
final color = WideColor.fromRGB(100, 150, 200);

// Adjust individual components
final lighterColor = color.withValue(0.8);
final moreSaturated = color.withSaturationV(0.9);
final redder = color.withRed(220);

// Mix colors
final mixedColor = color.mix(WideColor.fromRGB(200, 100, 50), otherInfluence: 0.3);
```

**Contrast and Accessibility**
```dart
final backgroundColor = WideColor.fromRGB(240, 240, 240);
final textColor = WideColor.fromRGB(50, 50, 50);

// Calculate contrast ratio
final contrastRatio = backgroundColor.contrast(textColor);

// Ensure minimum contrast
final adjustedTextColor = backgroundColor.fixContrast(
  textColor,
  minContrast: 4.5,
  preference: ContrastPreference.dark,
);
```

**Advanced Usage**
The library provides two main classes:

- WideColor: An immutable color representation for efficient storage and calculations.
- ToolColor: A mutable color class for interactive color manipulation.
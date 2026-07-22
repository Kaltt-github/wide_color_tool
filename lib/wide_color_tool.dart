/// Color conversion, mixing, luminance, and WCAG contrast utilities.
library;

import 'dart:math';

import 'package:flutter/material.dart';

/// The maximum value of an 8-bit color channel.
const int maxBit = 0xFF;

/// Converts a normalized [percentage] to an 8-bit channel value.
///
/// Values outside the `0.0` to `1.0` range are clamped.
int percentageToBit(double percentage) =>
    (percentage * maxBit).round().clamp(0, maxBit);

double _clampPercentage(num value) => value.clamp(0.0, 1.0).toDouble();

int _parseHexColor(String input) {
  var value = input.trim();
  if (value.startsWith('#')) {
    value = value.substring(1);
  } else if (value.toLowerCase().startsWith('0x')) {
    value = value.substring(2);
  }

  value = switch (value.length) {
    3 =>
      'FF${value.split('').map((character) => '$character$character').join()}',
    4 => value.split('').map((character) => '$character$character').join(),
    6 => 'FF$value',
    8 => value,
    _ => throw FormatException(
      'Expected RGB, ARGB, RRGGBB, or AARRGGBB hexadecimal color.',
      input,
    ),
  };

  return int.parse(value, radix: 16);
}

/// A color represented using [cyan], [magenta], [yellow], and [black].
@immutable
class CMYKColor {
  /// `[0.0..1.0]`
  final double cyan;

  /// `[0.0..1.0]`
  final double magenta;

  /// `[0.0..1.0]`
  final double yellow;

  /// `[0.0..1.0]`
  final double black;

  /// `[0.0..1.0]`
  final double opacity;

  /// Creates a CMYK color from normalized channels and [opacity].
  const CMYKColor.fromCMYK(
    this.cyan,
    this.magenta,
    this.yellow,
    this.black,
    this.opacity,
  ) : assert(0 <= cyan, cyan <= 1),
      assert(0 <= magenta, magenta <= 1),
      assert(0 <= yellow, yellow <= 1),
      assert(0 <= black, black <= 1),
      assert(0 <= opacity, opacity <= 1);

  /// Converts a Flutter [Color] to CMYK.
  factory CMYKColor.fromColor(Color color) {
    final black = 1.0 - max(color.r, max(color.g, color.b));
    if (black >= 1) {
      return CMYKColor.fromCMYK(0, 0, 0, 1, color.a);
    }

    final scale = 1 - black;
    return CMYKColor.fromCMYK(
      _clampPercentage((1 - color.r - black) / scale),
      _clampPercentage((1 - color.g - black) / scale),
      _clampPercentage((1 - color.b - black) / scale),
      black,
      color.a,
    );
  }

  /// Converts this CMYK value to a Flutter [Color].
  Color toColor() => Color.fromARGB(
    percentageToBit(opacity),
    percentageToBit((1 - cyan) * (1 - black)),
    percentageToBit((1 - magenta) * (1 - black)),
    percentageToBit((1 - yellow) * (1 - black)),
  );

  /// Returns a copy with the specified [cyan] channel.
  CMYKColor withCyan(double cyan) =>
      CMYKColor.fromCMYK(cyan, magenta, yellow, black, opacity);

  /// Returns a copy with the specified [magenta] channel.
  CMYKColor withMagenta(double magenta) =>
      CMYKColor.fromCMYK(cyan, magenta, yellow, black, opacity);

  /// Returns a copy with the specified [yellow] channel.
  CMYKColor withYellow(double yellow) =>
      CMYKColor.fromCMYK(cyan, magenta, yellow, black, opacity);

  /// Returns a copy with the specified [black] channel.
  CMYKColor withBlack(double black) =>
      CMYKColor.fromCMYK(cyan, magenta, yellow, black, opacity);

  /// Linearly interpolates between this color and another CMYKColor.
  CMYKColor lerp(CMYKColor other, double t) {
    if (t < 0 || t > 1) {
      throw RangeError.range(t, 0, 1, 't');
    }
    return CMYKColor.fromCMYK(
      cyan + (other.cyan - cyan) * t,
      magenta + (other.magenta - magenta) * t,
      yellow + (other.yellow - yellow) * t,
      black + (other.black - black) * t,
      opacity + (other.opacity - opacity) * t,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CMYKColor &&
          cyan == other.cyan &&
          magenta == other.magenta &&
          yellow == other.yellow &&
          black == other.black &&
          opacity == other.opacity;

  @override
  int get hashCode => Object.hash(cyan, magenta, yellow, black, opacity);
}

/// Color spaces supported by the mixing operations.
enum ColorSource {
  /// Red, green, and blue channels.
  rgb,

  /// Hue, saturation, and value channels.
  hsv,

  /// Hue, saturation, and lightness channels.
  hsl,

  /// Cyan, magenta, yellow, and black channels.
  cmyk,
}

/// The color space used by mixing operations when none is specified.
const defaultColorSource = ColorSource.hsv;

/// Direction used when adjusting a color to meet a contrast target.
enum ContrastPreference {
  /// Prefer a lighter result.
  light,

  /// Prefer a darker result.
  dark,

  /// Choose the closest result that meets the requested contrast.
  free,
}

/// The contrast adjustment strategy used when none is specified.
const defaultContrastPreference = ContrastPreference.free;

/// An immutable color with RGB, HSV, HSL, CMYK, alpha, and contrast utilities.
///
/// Use [ToolColor] when a mutable color is required.
class WideColor {
  /// Normalize the luminance of an RGB component.
  /// The value is normalized according to the formula defined by
  /// Web Content Accessibility Guidelines (WCAG) 2.0
  /// https://www.w3.org/TR/WCAG20/#relativeluminancedef
  static double _normalizeLuminance(int rgb) {
    final normalized = rgb / maxBit;
    return normalized <= 0.03928
        ? normalized / 12.92
        : pow((normalized + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Calculate the relative luminance of a [WideColor] instance.
  /// This follows the WCAG 2.0 guidelines for relative luminance.
  static double getLuminance(WideColor color) =>
      0.2126 * _normalizeLuminance(color.red) +
      0.7152 * _normalizeLuminance(color.green) +
      0.0722 * _normalizeLuminance(color.blue);

  static void _validateContrast(num minContrast) {
    if (minContrast < 1 || minContrast > 21) {
      throw RangeError.range(minContrast, 1, 21, 'minContrast');
    }
  }

  static WideColor _adjustContrast(
    WideColor base,
    WideColor toContrast, {
    required num minContrast,
    required bool lighten,
  }) {
    _validateContrast(minContrast);
    if (base.contrast(toContrast) >= minContrast) {
      return toContrast;
    }

    final endpoint = WideColor.fromRGB(
      lighten ? maxBit : 0,
      lighten ? maxBit : 0,
      lighten ? maxBit : 0,
      alpha: toContrast.alpha,
    );
    if (base.contrast(endpoint) < minContrast) {
      return endpoint;
    }

    WideColor interpolate(double amount) => WideColor.fromRGB(
      (toContrast.red + (endpoint.red - toContrast.red) * amount).round(),
      (toContrast.green + (endpoint.green - toContrast.green) * amount).round(),
      (toContrast.blue + (endpoint.blue - toContrast.blue) * amount).round(),
      alpha: toContrast.alpha,
    );

    var low = 0.0;
    var high = 1.0;
    for (var iteration = 0; iteration < 24; iteration++) {
      final midpoint = (low + high) / 2;
      if (base.contrast(interpolate(midpoint)) >= minContrast) {
        high = midpoint;
      } else {
        low = midpoint;
      }
    }
    return interpolate(high);
  }

  /// Lightens [toContrast] until it reaches [minContrast] against [base].
  static WideColor ensureLightContrast(
    WideColor base,
    WideColor toContrast, {
    num minContrast = 4.5,
  }) => _adjustContrast(
    base,
    toContrast,
    minContrast: minContrast,
    lighten: true,
  );

  /// Darkens [toContrast] until it reaches [minContrast] against [base].
  static WideColor ensureDarkContrast(
    WideColor base,
    WideColor toContrast, {
    num minContrast = 4.5,
  }) => _adjustContrast(
    base,
    toContrast,
    minContrast: minContrast,
    lighten: false,
  );

  /// Adjust the [toContrast] color to ensure a minimum contrast ratio against [base].
  /// This method will adjust the color based on the [preference] for light or dark contrast.
  /// If [preference] is [ContrastPreference.free], it will choose the adjustment
  /// based on the relative luminance of the colors.
  static WideColor ensureContrast(
    WideColor base,
    WideColor toContrast, {
    num minContrast = 4.5,
    ContrastPreference preference = defaultContrastPreference,
  }) {
    _validateContrast(minContrast);
    final contrast = base.contrast(toContrast);
    if (contrast >= minContrast) {
      return toContrast;
    }
    switch (preference) {
      case ContrastPreference.dark:
        return ensureDarkContrast(base, toContrast, minContrast: minContrast);
      case ContrastPreference.light:
        return ensureLightContrast(base, toContrast, minContrast: minContrast);
      case ContrastPreference.free:
        final light = ensureLightContrast(
          base,
          toContrast,
          minContrast: minContrast,
        );
        final dark = ensureDarkContrast(
          base,
          toContrast,
          minContrast: minContrast,
        );
        final lightMeetsTarget = base.contrast(light) >= minContrast;
        final darkMeetsTarget = base.contrast(dark) >= minContrast;
        if (lightMeetsTarget != darkMeetsTarget) {
          return lightMeetsTarget ? light : dark;
        }
        int distance(WideColor color) =>
            (color.red - toContrast.red).abs() +
            (color.green - toContrast.green).abs() +
            (color.blue - toContrast.blue).abs();
        return distance(light) <= distance(dark) ? light : dark;
    }
  }

  /// Calculate the contrast ratio between two [WideColor] instances [a] and [b].
  /// This follows the WCAG 2.0 guidelines for contrast ratios:
  /// - 3:1 for large text (at least 18pt or 14pt bold)
  /// - 4.5:1 for normal text
  /// - 7:1 for enhanced accessibility
  static double getContrast(WideColor a, WideColor b) {
    final lighter = max(a.luminance, b.luminance);
    final darker = min(a.luminance, b.luminance);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// `[0x00000000..0xFFFFFFFF]`
  /// `[0..4294967295]`
  /// Bit value from ARGB
  final int bitValue;

  /// `[0..255]`
  /// Alpha from ARGB
  int get alpha => (0xFF000000 & bitValue) >> 24;

  /// `[0.0..1.0]`
  /// Opacity from ARGB
  double get opacity => alpha / maxBit;

  /// `[0..255]`
  /// Red from RGB
  int get red => (0x00FF0000 & bitValue) >> 16;

  /// `[0..255]`
  /// Green from RGB
  int get green => (0x0000FF00 & bitValue) >> 8;

  /// `[0..255]`
  /// Blue from RGB
  int get blue => 0x000000FF & bitValue;

  /// `[0..360]`
  /// Hue from HSV or HSL
  final int hue;

  /// `[0.0..1.0]`
  /// Value from HSV
  final double value;

  /// `[0.0..1.0]`
  /// Saturation from HSV
  final double saturationV;

  /// `[0.0..1.0]`
  /// Lightness from HSL
  final double light;

  /// `[0.0..1.0]`
  /// Saturation from HSL
  final double saturationL;

  /// `[0.0..1.0]`
  /// Cyan from CMYK
  double get cyan => black >= 1
      ? 0
      : _clampPercentage((1 - red / maxBit - black) / (1 - black));

  /// `[0.0..1.0]`
  /// Magenta from CMYK
  double get magenta => black >= 1
      ? 0
      : _clampPercentage((1 - green / maxBit - black) / (1 - black));

  /// `[0.0..1.0]`
  /// Yellow from CMYK
  double get yellow => black >= 1
      ? 0
      : _clampPercentage((1 - blue / maxBit - black) / (1 - black));

  /// `[0.0..1.0]`
  /// Black from CMYK
  final double black;

  /// `[0.0..1.0]`
  /// Key from CMYK aka Black
  double get key => black;

  /// This value as a Flutter [Color].
  Color get color => Color(bitValue);

  /// This value in the HSV color space.
  HSVColor get hsv =>
      HSVColor.fromAHSV(opacity, hue.toDouble(), saturationV, value);

  /// This value in the HSL color space.
  HSLColor get hsl =>
      HSLColor.fromAHSL(opacity, hue.toDouble(), saturationL, light);

  /// This value in the CMYK color space.
  CMYKColor get cmyk =>
      CMYKColor.fromCMYK(cyan, magenta, yellow, black, opacity);

  /// An uppercase `#AARRGGBB` representation of this color.
  String get string =>
      '#${bitValue.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  @override
  String toString([String prefix = '#']) => '$prefix${string.substring(1)}';

  const WideColor._({
    required this.bitValue,
    required this.hue,
    required this.value,
    required this.saturationV,
    required this.light,
    required this.saturationL,
    required this.black,
  });

  WideColor._complete(Color color, HSVColor hsv, HSLColor hsl)
    : this._(
        bitValue: color.toARGB32(),
        hue: hsv.hue.toInt(),
        value: hsv.value,
        saturationV: hsv.saturation,
        light: hsl.lightness,
        saturationL: hsl.saturation,
        black: 1.0 - max(color.r, max(color.g, color.b)),
      );

  WideColor._completeV(Color color, HSVColor hsv)
    : this._complete(color, hsv, HSLColor.fromColor(color));

  WideColor._completeL(Color color, HSLColor hsl)
    : this._complete(color, HSVColor.fromColor(color), hsl);

  /// Creates a color from a Flutter [Color].
  WideColor.fromColor(Color color)
    : this._complete(
        color,
        HSVColor.fromColor(color),
        HSLColor.fromColor(color),
      );

  /// Creates a color from a 32-bit ARGB [bitValue].
  WideColor.fromBitValue(int bitValue) : this.fromColor(Color(bitValue));

  /// Creates a color from 8-bit RGB channels and optional transparency.
  WideColor.fromRGB(int r, int g, int b, {int? alpha, double? opacity})
    : this.fromColor(
        opacity != null
            ? Color.fromRGBO(r, g, b, opacity)
            : Color.fromARGB(alpha ?? maxBit, r, g, b),
      );

  /// Creates a color from a Flutter [HSVColor].
  WideColor.fromHSVColor(HSVColor color)
    : this._completeV(color.toColor(), color);

  /// Creates a color from HSV channels and optional transparency.
  WideColor.fromHSV(int h, double s, double v, {int? alpha, double? opacity})
    : this.fromHSVColor(
        HSVColor.fromAHSV(
          alpha != null ? alpha / maxBit : opacity ?? 1.0,
          h.toDouble(),
          s,
          v,
        ),
      );

  /// Creates a color from a Flutter [HSLColor].
  WideColor.fromHSLColor(HSLColor color)
    : this._completeL(color.toColor(), color);

  /// Creates a color from HSL channels and optional transparency.
  WideColor.fromHSL(int h, double s, double l, {int? alpha, double? opacity})
    : this.fromHSLColor(
        HSLColor.fromAHSL(
          alpha != null ? alpha / maxBit : opacity ?? 1.0,
          h.toDouble(),
          s,
          l,
        ),
      );

  /// Creates a color from normalized CMYK channels and optional transparency.
  WideColor.fromCMYK(
    double c,
    double m,
    double y,
    double k, {
    int? alpha,
    double? opacity,
  }) : this.fromCMYKColor(
         CMYKColor.fromCMYK(
           c,
           m,
           y,
           k,
           alpha != null ? alpha / maxBit : opacity ?? 1,
         ),
       );

  /// Creates a color from a [CMYKColor].
  WideColor.fromCMYKColor(CMYKColor color) : this.fromColor(color.toColor());

  /// Parses RGB or ARGB hexadecimal [value].
  WideColor.fromString(String value) : this.fromBitValue(_parseHexColor(value));

  /// Returns a copy with the specified 8-bit [alpha] channel.
  WideColor withAlpha(int alpha) => WideColor.fromColor(color.withAlpha(alpha));

  /// Returns a copy with the specified normalized [opacity].
  WideColor withOpacity(double opacity) =>
      withAlpha((maxBit * opacity).round());

  /// Returns a copy with any supplied RGB or transparency channels replaced.
  WideColor withRGB({
    int? red,
    int? green,
    int? blue,
    int? alpha,
    double? opacity,
  }) => WideColor.fromRGB(
    red ?? this.red,
    green ?? this.green,
    blue ?? this.blue,
    alpha: opacity != null ? (opacity * maxBit).round() : alpha ?? this.alpha,
  );

  /// Returns a copy with the specified 8-bit [red] channel.
  WideColor withRed(int red) => withRGB(red: red);

  /// Returns a copy with the specified 8-bit [green] channel.
  WideColor withGreen(int green) => withRGB(green: green);

  /// Returns a copy with the specified 8-bit [blue] channel.
  WideColor withBlue(int blue) => withRGB(blue: blue);

  /// Returns a copy with any supplied HSV or transparency channels replaced.
  WideColor withHSV({
    int? hue,
    double? saturation,
    double? value,
    int? alpha,
    double? opacity,
  }) => WideColor.fromHSV(
    hue ?? this.hue,
    saturation ?? saturationV,
    value ?? this.value,
    alpha: opacity != null ? (opacity * maxBit).round() : alpha ?? this.alpha,
  );

  /// Returns a copy with the specified [hue].
  WideColor withHue(int hue) => withHSV(hue: hue);

  /// Returns a copy with the specified HSV [saturation].
  WideColor withSaturationV(double saturation) =>
      withHSV(saturation: saturation);

  /// Returns a copy with the specified HSV [value].
  WideColor withValue(double value) => withHSV(value: value);

  /// Returns a copy with any supplied HSL or transparency channels replaced.
  WideColor withHSL({
    int? hue,
    double? saturation,
    double? light,
    int? alpha,
    double? opacity,
  }) => WideColor.fromHSL(
    hue ?? this.hue,
    saturation ?? saturationL,
    light ?? this.light,
    alpha: opacity != null ? (opacity * maxBit).round() : alpha ?? this.alpha,
  );

  /// Returns a copy with the specified HSL [saturation].
  WideColor withSaturationL(double saturation) =>
      withHSL(saturation: saturation);

  /// Returns a copy with the specified HSL [light] value.
  WideColor withLight(double light) => withHSL(light: light);

  /// Returns a copy with any supplied CMYK or transparency channels replaced.
  WideColor withCMYK({
    double? cyan,
    double? magenta,
    double? yellow,
    double? black,
    int? alpha,
    double? opacity,
  }) => WideColor.fromCMYK(
    cyan ?? this.cyan,
    magenta ?? this.magenta,
    yellow ?? this.yellow,
    black ?? this.black,
    alpha: opacity != null ? (opacity * maxBit).round() : alpha ?? this.alpha,
  );

  /// Returns a copy with the specified [cyan] channel.
  WideColor withCyan(double cyan) => withCMYK(cyan: cyan);

  /// Returns a copy with the specified [magenta] channel.
  WideColor withMagenta(double magenta) => withCMYK(magenta: magenta);

  /// Returns a copy with the specified [yellow] channel.
  WideColor withYellow(double yellow) => withCMYK(yellow: yellow);

  /// Returns a copy with the specified [black] channel.
  WideColor withBlack(double black) => withCMYK(black: black);

  /// Returns an independent immutable copy of this color.
  WideColor copy() => WideColor._(
    bitValue: bitValue,
    hue: hue,
    value: value,
    saturationV: saturationV,
    light: light,
    saturationL: saturationL,
    black: black,
  );

  /// Returns a mutable copy of this color.
  ToolColor toTool() => ToolColor.fromColor(color);

  /// Returns an independent immutable copy of this color.
  WideColor toWide() => copy();

  /// Mixes [a] and [b] in the requested color [source].
  factory WideColor.mix(
    WideColor a,
    WideColor b, {
    double aInfluence = 0.5,
    ColorSource source = defaultColorSource,
  }) {
    if (aInfluence < 0 || aInfluence > 1) {
      throw RangeError.range(aInfluence, 0, 1, 'aInfluence');
    }
    switch (source) {
      case ColorSource.rgb:
        return WideColor.fromRGB(
          (a.red * aInfluence + b.red * (1 - aInfluence)).toInt(),
          (a.green * aInfluence + b.green * (1 - aInfluence)).toInt(),
          (a.blue * aInfluence + b.blue * (1 - aInfluence)).toInt(),
          opacity: a.opacity * aInfluence + b.opacity * (1 - aInfluence),
        );
      case ColorSource.hsv:
        return WideColor.fromHSV(
          (a.hue * aInfluence + b.hue * (1 - aInfluence)).toInt(),
          a.saturationV * aInfluence + b.saturationV * (1 - aInfluence),
          a.value * aInfluence + b.value * (1 - aInfluence),
          opacity: a.opacity * aInfluence + b.opacity * (1 - aInfluence),
        );
      case ColorSource.hsl:
        return WideColor.fromHSL(
          (a.hue * aInfluence + b.hue * (1 - aInfluence)).toInt(),
          a.saturationL * aInfluence + b.saturationL * (1 - aInfluence),
          a.light * aInfluence + b.light * (1 - aInfluence),
          opacity: a.opacity * aInfluence + b.opacity * (1 - aInfluence),
        );
      case ColorSource.cmyk:
        return WideColor.fromCMYK(
          a.cyan * aInfluence + b.cyan * (1 - aInfluence),
          a.magenta * aInfluence + b.magenta * (1 - aInfluence),
          a.yellow * aInfluence + b.yellow * (1 - aInfluence),
          a.black * aInfluence + b.black * (1 - aInfluence),
          opacity: a.opacity * aInfluence + b.opacity * (1 - aInfluence),
        );
    }
  }

  /// Mixes this color with [other] color, adjusting influence and color space.
  ///
  /// [otherInfluence] determines the amount of influence [other] color has in the mix,
  /// with 0.0 resulting in no change and 1.0 resulting in fully [other] color.
  ///
  /// [source] specifies the color space used for mixing.
  ///
  /// Returns a new [WideColor] instance representing the mixed color.
  WideColor mix(
    WideColor other, {
    double otherInfluence = 0.5,
    ColorSource source = defaultColorSource,
  }) => WideColor.mix(other, this, aInfluence: otherInfluence, source: source);

  /// Calculates the luminance of this color.
  ///
  /// Returns the relative luminance of the color, which is essential for
  /// determining color contrast in accessibility guidelines.
  double get luminance => getLuminance(this);

  /// Calculates the contrast ratio between this color and [other].
  ///
  /// Returns the contrast ratio, which helps in determining the readability
  /// and accessibility of text against the background color.
  double contrast(WideColor other) => getContrast(this, other);

  /// Adjusts the color [other] to meet a minimum contrast ratio against this color.
  ///
  /// [minContrast] specifies the minimum acceptable contrast ratio.
  ///
  /// [preference] determines whether to adjust [other] color to ensure a darker,
  /// lighter, or any available contrast against this color.
  ///
  /// Returns a new [WideColor] instance adjusted to meet the specified contrast requirements.
  WideColor fixContrast(
    WideColor other, {
    num minContrast = 4.5,
    ContrastPreference preference = defaultContrastPreference,
  }) => ensureContrast(
    this,
    other,
    preference: preference,
    minContrast: minContrast,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is WideColor &&
          bitValue == other.bitValue;

  @override
  int get hashCode => bitValue.hashCode;
}

/// A mutable color with RGB, HSV, HSL, CMYK, alpha, and contrast utilities.
///
/// Use [WideColor] when an immutable color is preferred.
class ToolColor implements WideColor {
  /// Lightens [toContrast] until it reaches [minContrast] against [base].
  static WideColor ensureLightContrast(
    WideColor base,
    WideColor toContrast, {
    num minContrast = 4.5,
  }) =>
      WideColor.ensureLightContrast(base, toContrast, minContrast: minContrast);

  /// Darkens [toContrast] until it reaches [minContrast] against [base].
  static WideColor ensureDarkContrast(
    WideColor base,
    WideColor toContrast, {
    num minContrast = 4.5,
  }) =>
      WideColor.ensureDarkContrast(base, toContrast, minContrast: minContrast);

  /// Adjust the [toContrast] color to ensure a minimum contrast ratio against [base].
  /// This method will adjust the color based on the [preference] for light or dark contrast.
  /// If [preference] is [ContrastPreference.free], it will choose the adjustment
  /// based on the relative luminance of the colors.
  static WideColor ensureContrast(
    WideColor base,
    WideColor toContrast, {
    num minContrast = 4.5,
    ContrastPreference preference = defaultContrastPreference,
  }) => WideColor.ensureContrast(
    base,
    toContrast,
    minContrast: minContrast,
    preference: preference,
  );

  /// Calculates the WCAG relative luminance of [color].
  static double getLuminance(WideColor color) => WideColor.getLuminance(color);

  /// Calculate the contrast ratio between two [WideColor] instances [a] and [b].
  /// This follows the WCAG 2.0 guidelines for contrast ratios:
  /// - 3:1 for large text (at least 18pt or 14pt bold)
  /// - 4.5:1 for normal text
  /// - 7:1 for enhanced accessibility
  static double getContrast(WideColor a, WideColor b) =>
      WideColor.getContrast(a, b);

  Color? _color;
  HSVColor? _hsv;
  HSLColor? _hsl;
  CMYKColor? _cmyk;

  @override
  int get bitValue => color.toARGB32();
  set bitValue(int value) => color = Color(value);

  @override
  int get alpha => percentageToBit(color.a);
  set alpha(int value) => color = color.withAlpha(value);

  @override
  double get opacity => color.a;
  set opacity(double value) => alpha = percentageToBit(value);

  @override
  int get red => percentageToBit(color.r);
  set red(int value) => color = color.withRed(value);

  @override
  int get green => percentageToBit(color.g);
  set green(int value) => color = color.withGreen(value);

  @override
  int get blue => percentageToBit(color.b);
  set blue(int value) => color = color.withBlue(value);

  @override
  int get hue => (_hsv?.hue ?? _hsl?.hue ?? hsv.hue).toInt();
  set hue(int value) => hsv = hsv.withHue(value.toDouble());

  @override
  double get value => hsv.value;
  set value(double value) => hsv = hsv.withValue(value);

  @override
  double get saturationV => hsv.saturation;
  set saturationV(double value) => hsv = hsv.withSaturation(value);

  @override
  double get light => hsl.lightness;
  set light(double value) => hsl = hsl.withLightness(value);

  @override
  double get saturationL => hsl.saturation;
  set saturationL(double value) => hsl = hsl.withSaturation(value);

  @override
  double get cyan => cmyk.cyan;
  set cyan(double value) => cmyk = cmyk.withCyan(value);

  @override
  double get magenta => cmyk.magenta;
  set magenta(double value) => cmyk = cmyk.withMagenta(value);

  @override
  double get yellow => cmyk.yellow;
  set yellow(double value) => cmyk = cmyk.withYellow(value);

  @override
  double get black => cmyk.black;
  set black(double value) => cmyk = cmyk.withBlack(value);

  @override
  double get key => black;
  set key(double value) => black = value;

  @override
  Color get color => _color ??=
      _hsv?.toColor() ??
      _hsl?.toColor() ??
      _cmyk?.toColor() ??
      const Color(0x00000000);
  set color(Color color) {
    _color = color;
    _hsl = _hsv = _cmyk = null;
  }

  @override
  HSVColor get hsv => _hsv ??= HSVColor.fromColor(color);
  set hsv(HSVColor color) {
    _hsv = color;
    _color = _hsl = _cmyk = null;
  }

  @override
  HSLColor get hsl => _hsl ??= HSLColor.fromColor(color);
  set hsl(HSLColor color) {
    _hsl = color;
    _color = _hsv = _cmyk = null;
  }

  @override
  CMYKColor get cmyk => _cmyk ??= CMYKColor.fromColor(color);
  set cmyk(CMYKColor color) {
    _cmyk = color;
    _color = _hsv = _hsl = null;
  }

  @override
  String get string =>
      '#${bitValue.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  set string(String value) => bitValue = _parseHexColor(value);

  @override
  String toString([String prefix = '#']) => '$prefix${string.substring(1)}';

  /// Creates a mutable color from a Flutter [Color].
  ToolColor.fromColor(Color color) : _color = color;

  /// Creates a mutable color from a 32-bit ARGB [bitValue].
  ToolColor.fromBitValue(int bitValue) : this.fromColor(Color(bitValue));

  /// Creates a mutable color from 8-bit RGB channels and transparency.
  ToolColor.fromRGB(int r, int g, int b, {int? alpha, double? opacity})
    : this.fromColor(
        opacity != null
            ? Color.fromRGBO(r, g, b, opacity)
            : Color.fromARGB(alpha ?? maxBit, r, g, b),
      );

  /// Creates a mutable color from a Flutter [HSVColor].
  ToolColor.fromHSVColor(HSVColor color) : _hsv = color;

  /// Creates a mutable color from HSV channels and optional transparency.
  ToolColor.fromHSV(int h, double s, double v, {int? alpha, double? opacity})
    : this.fromHSVColor(
        HSVColor.fromAHSV(
          alpha != null ? alpha / maxBit : opacity ?? 1.0,
          h.toDouble(),
          s,
          v,
        ),
      );

  /// Creates a mutable color from a Flutter [HSLColor].
  ToolColor.fromHSLColor(HSLColor color) : _hsl = color;

  /// Creates a mutable color from HSL channels and optional transparency.
  ToolColor.fromHSL(int h, double s, double l, {int? alpha, double? opacity})
    : this.fromHSLColor(
        HSLColor.fromAHSL(
          alpha != null ? alpha / maxBit : opacity ?? 1.0,
          h.toDouble(),
          s,
          l,
        ),
      );

  /// Creates a mutable color from normalized CMYK channels and transparency.
  ToolColor.fromCMYK(
    double c,
    double m,
    double y,
    double k, {
    int? alpha,
    double? opacity,
  }) : this.fromCMYKColor(
         CMYKColor.fromCMYK(
           c,
           m,
           y,
           k,
           alpha != null ? alpha / maxBit : opacity ?? 1,
         ),
       );

  /// Creates a mutable color from a [CMYKColor].
  ToolColor.fromCMYKColor(CMYKColor color) : _cmyk = color;

  /// Parses a mutable color from RGB or ARGB hexadecimal [value].
  ToolColor.fromString(String value) : this.fromBitValue(_parseHexColor(value));

  @override
  ToolColor withAlpha(int alpha) => ToolColor.fromColor(color.withAlpha(alpha));

  @override
  ToolColor withOpacity(double opacity) =>
      withAlpha((maxBit * opacity).round());

  @override
  ToolColor withRGB({
    int? red,
    int? green,
    int? blue,
    int? alpha,
    double? opacity,
  }) => ToolColor.fromRGB(
    red ?? this.red,
    green ?? this.green,
    blue ?? this.blue,
    alpha: opacity != null ? (opacity * maxBit).round() : alpha ?? this.alpha,
  );

  @override
  ToolColor withRed(int red) => withRGB(red: red);
  @override
  ToolColor withGreen(int green) => withRGB(green: green);
  @override
  ToolColor withBlue(int blue) => withRGB(blue: blue);

  @override
  ToolColor withHSV({
    int? hue,
    double? saturation,
    double? value,
    int? alpha,
    double? opacity,
  }) => ToolColor.fromHSV(
    hue ?? this.hue,
    saturation ?? saturationV,
    value ?? this.value,
    alpha: opacity != null ? (opacity * maxBit).round() : alpha ?? this.alpha,
  );

  @override
  ToolColor withHue(int hue) => withHSV(hue: hue);
  @override
  ToolColor withSaturationV(double saturation) =>
      withHSV(saturation: saturation);
  @override
  ToolColor withValue(double value) => withHSV(value: value);

  @override
  ToolColor withHSL({
    int? hue,
    double? saturation,
    double? light,
    int? alpha,
    double? opacity,
  }) => ToolColor.fromHSL(
    hue ?? this.hue,
    saturation ?? saturationL,
    light ?? this.light,
    alpha: opacity != null ? (opacity * maxBit).round() : alpha ?? this.alpha,
  );

  @override
  ToolColor withSaturationL(double saturation) =>
      withHSL(saturation: saturation);
  @override
  ToolColor withLight(double light) => withHSL(light: light);

  @override
  ToolColor withCMYK({
    double? cyan,
    double? magenta,
    double? yellow,
    double? black,
    int? alpha,
    double? opacity,
  }) => ToolColor.fromCMYK(
    cyan ?? this.cyan,
    magenta ?? this.magenta,
    yellow ?? this.yellow,
    black ?? this.black,
    alpha: opacity != null ? (opacity * maxBit).round() : alpha ?? this.alpha,
  );

  @override
  ToolColor withCyan(double cyan) => withCMYK(cyan: cyan);
  @override
  ToolColor withMagenta(double magenta) => withCMYK(magenta: magenta);
  @override
  ToolColor withYellow(double yellow) => withCMYK(yellow: yellow);
  @override
  ToolColor withBlack(double black) => withCMYK(black: black);

  @override
  ToolColor copy() => ToolColor.fromColor(color);
  @override
  WideColor toWide() => WideColor.fromColor(color);
  @override
  ToolColor toTool() => copy();

  /// Mixes [a] and [b] in the requested color [source].
  factory ToolColor.mix(
    WideColor a,
    WideColor b, {
    double aInfluence = 0.5,
    ColorSource source = defaultColorSource,
  }) {
    if (aInfluence < 0 || aInfluence > 1) {
      throw RangeError.range(aInfluence, 0, 1, 'aInfluence');
    }
    switch (source) {
      case ColorSource.rgb:
        return ToolColor.fromRGB(
          (a.red * aInfluence + b.red * (1 - aInfluence)).toInt(),
          (a.green * aInfluence + b.green * (1 - aInfluence)).toInt(),
          (a.blue * aInfluence + b.blue * (1 - aInfluence)).toInt(),
          opacity: a.opacity * aInfluence + b.opacity * (1 - aInfluence),
        );
      case ColorSource.hsv:
        return ToolColor.fromHSV(
          (a.hue * aInfluence + b.hue * (1 - aInfluence)).toInt(),
          a.saturationV * aInfluence + b.saturationV * (1 - aInfluence),
          a.value * aInfluence + b.value * (1 - aInfluence),
          opacity: a.opacity * aInfluence + b.opacity * (1 - aInfluence),
        );
      case ColorSource.hsl:
        return ToolColor.fromHSL(
          (a.hue * aInfluence + b.hue * (1 - aInfluence)).toInt(),
          a.saturationL * aInfluence + b.saturationL * (1 - aInfluence),
          a.light * aInfluence + b.light * (1 - aInfluence),
          opacity: a.opacity * aInfluence + b.opacity * (1 - aInfluence),
        );
      case ColorSource.cmyk:
        return ToolColor.fromCMYK(
          a.cyan * aInfluence + b.cyan * (1 - aInfluence),
          a.magenta * aInfluence + b.magenta * (1 - aInfluence),
          a.yellow * aInfluence + b.yellow * (1 - aInfluence),
          a.black * aInfluence + b.black * (1 - aInfluence),
          opacity: a.opacity * aInfluence + b.opacity * (1 - aInfluence),
        );
    }
  }

  @override
  ToolColor mix(
    WideColor other, {
    double otherInfluence = 0.5,
    ColorSource source = defaultColorSource,
  }) => ToolColor.mix(other, this, aInfluence: otherInfluence, source: source);

  @override
  double get luminance => getLuminance(this);

  @override
  double contrast(WideColor other) => getContrast(this, other);

  @override
  WideColor fixContrast(
    WideColor other, {
    num minContrast = 4.5,
    ContrastPreference preference = defaultContrastPreference,
  }) => ensureContrast(
    this,
    other,
    preference: preference,
    minContrast: minContrast,
  );
}

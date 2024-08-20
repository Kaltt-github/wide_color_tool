import 'dart:math';

import 'package:flutter/material.dart';

const bit = 0XFF;

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

  const CMYKColor.fromCMYK(
      this.cyan, this.magenta, this.yellow, this.black, this.opacity)
      : assert(0 <= cyan, cyan <= 1),
        assert(0 <= magenta, magenta <= 1),
        assert(0 <= yellow, yellow <= 1),
        assert(0 <= black, black <= 1),
        assert(0 <= opacity, opacity <= 1);

  factory CMYKColor.fromColor(Color color) {
    final black = 1 - [color.red, color.green, color.blue].reduce(min) / bit;
    return CMYKColor.fromCMYK(
        1 - color.red / bit - black,
        1 - color.green / bit - black,
        1 - color.blue / bit - black,
        black,
        color.opacity);
  }

  Color toColor() => Color.fromRGBO(
      (255 * (1 - cyan) * (1 - black)).round(),
      (255 * (1 - magenta) * (1 - black)).round(),
      (255 * (1 - yellow) * (1 - black)).round(),
      opacity);

  CMYKColor withcyan(double cyan) =>
      CMYKColor.fromCMYK(cyan, magenta, yellow, black, opacity);

  CMYKColor withMagetna(double yellow) =>
      CMYKColor.fromCMYK(cyan, magenta, yellow, black, opacity);

  CMYKColor withYellow(double yellow) =>
      CMYKColor.fromCMYK(cyan, magenta, yellow, black, opacity);

  CMYKColor withBlack(double black) =>
      CMYKColor.fromCMYK(cyan, magenta, yellow, black, opacity);

  /// Linearly interpolates between this color and another CMYKColor.
  CMYKColor lerp(CMYKColor other, double t) => CMYKColor.fromCMYK(
        cyan * (1 - t) + (other.cyan - cyan) * t,
        magenta * (1 - t) + (other.magenta - magenta) * t,
        yellow * (1 - t) + (other.yellow - yellow) * t,
        black * (1 - t) + (other.black - black) * t,
        opacity * (1 - t) + (other.opacity - opacity) * t,
      );
}

enum ColorSource { rgb, hsv, hsl, cmyk }

const defaultColorSource = ColorSource.hsv;

enum ContrastPreference { light, dark, free }

const defaultContrastPreference = ContrastPreference.free;

/// Read only color which handles RGB, HSV, HSL, CMYK, Alpha, Opacity and Contrast
///
/// Use [ToolColor] for write and read
class WideColor {
  /// Normalize the luminance of an RGB component.
  /// The value is normalized according to the formula defined by
  /// Web Content Accessibility Guidelines (WCAG) 2.0
  /// https://www.w3.org/TR/WCAG20/#relativeluminancedef
  static num _normalizeLuminance(int rgb) {
    final normalized = rgb / bit;
    return normalized <= 0.03928
        ? normalized / 12.92
        : pow((normalized + 0.055) / 1.055, 2.4);
  }

  /// Calculate the relative luminance of a [WideColor] instance.
  /// This follows the WCAG 2.0 guidelines for relative luminance.
  static num getLuminance(WideColor color) =>
      0.2126 * _normalizeLuminance(color.red) +
      0.7152 * _normalizeLuminance(color.green) +
      0.0722 * _normalizeLuminance(color.blue);

  /// Ensure a light contrast ratio by adjusting the [toContrast] color.
  /// If the contrast ratio between [base] and [toContrast] is below [minContrast],
  /// the [toContrast] color will be adjusted to meet the minimum contrast ratio.
  static WideColor asureLightContrast(WideColor base, WideColor toContrast,
      {num minContrast = 4.5}) {
    final contrast = base.contrast(toContrast);
    if (contrast >= minContrast || toContrast.value == 1) {
      return toContrast;
    }
    final newValue = (toContrast.value * (minContrast / contrast));
    return asureLightContrast(
        base,
        toContrast.withValue(
            (newValue < 1 && (toContrast.value - newValue).abs() < 0.01
                    ? toContrast.value + 0.01
                    : newValue)
                .clamp(0, 1)),
        minContrast: minContrast);
  }

  /// Ensure a dark contrast ratio by adjusting the [toContrast] color.
  /// If the contrast ratio between [base] and [toContrast] is below [minContrast],
  /// the [toContrast] color will be adjusted to meet the minimum contrast ratio.
  static WideColor asureDarkContrast(WideColor base, WideColor toContrast,
      {num minContrast = 4.5}) {
    final contrast = base.contrast(toContrast);
    if (contrast >= minContrast || toContrast.value == 0) {
      return toContrast;
    }
    final newValue = (toContrast.value * (1 / (minContrast / contrast)));
    return asureDarkContrast(
        base,
        toContrast.withValue(
            (newValue > 0 && (toContrast.value - newValue).abs() < 0.01
                    ? toContrast.value - 0.01
                    : newValue)
                .clamp(0, 1)),
        minContrast: minContrast);
  }

  /// Adjust the [toContrast] color to ensure a minimum contrast ratio against [base].
  /// This method will adjust the color based on the [preference] for light or dark contrast.
  /// If [preference] is [ContrastPreference.free], it will choose the adjustment
  /// based on the relative luminance of the colors.
  static WideColor asureContrast(WideColor base, WideColor toContrast,
      {num minContrast = 4.5,
      ContrastPreference preference = defaultContrastPreference}) {
    final contrast = base.contrast(toContrast);
    if (contrast >= minContrast) {
      return toContrast;
    }
    switch (preference) {
      case ContrastPreference.dark:
        return asureDarkContrast(base, toContrast, minContrast: minContrast);
      case ContrastPreference.light:
        return asureLightContrast(base, toContrast, minContrast: minContrast);
      case ContrastPreference.free:
        final bl = base.luminance;
        final cl = toContrast.luminance;
        return bl > cl
            ? asureDarkContrast(base, toContrast, minContrast: minContrast)
            : asureLightContrast(base, toContrast, minContrast: minContrast);
    }
  }

  /// Calculate the contrast ratio between two [WideColor] instances [a] and [b].
  /// This follows the WCAG 2.0 guidelines for contrast ratios:
  /// - 3:1 for large text (at least 18pt or 14pt bold)
  /// - 4.5:1 for normal text
  /// - 7:1 for enhanced accessibility
  static num getContrast(WideColor a, WideColor b) => a.bitValue > b.bitValue
      ? (a.luminance + 0.05) / (b.luminance + 0.05)
      : (b.luminance + 0.05) / (a.luminance + 0.05);

  /// `[0x00000000..0xFFFFFFFF]`
  /// `[0..4294967295]`
  /// Bit value from ARGB
  final int bitValue;

  /// `[0..225]`
  /// Alpha from ARGB
  int get alpha => (0xFF000000 & bitValue) >> 24;

  /// `[0.0..1.0]`
  /// Opacity from ORGB
  double get opacity => alpha / bit;

  /// `[0..225]`
  /// Red from RGB
  int get red => (0x00FF0000 & bitValue) >> 16;

  /// `[0..225]`
  /// Green from RGB
  int get green => (0x0000FF00 & bitValue) >> 8;

  /// `[0..225]`
  /// Blue from RGB
  int get blue => (0x000000FF & bitValue) >> 0;

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
  /// cyan from CMYK
  double get cyan => 1 - red / bit - black;

  /// `[0.0..1.0]`
  /// Magenta from CMYK
  double get magenta => 1 - green / bit - black;

  /// `[0.0..1.0]`
  /// Yellow from CMYK
  double get yellow => 1 - blue / bit - black;

  /// `[0.0..1.0]`
  /// Black from CMYK
  final double black;

  /// `[0.0..1.0]`
  /// Key from CMYK aka Black
  double get key => black;

  Color get color => Color(bitValue);

  HSVColor get hsv =>
      HSVColor.fromAHSV(opacity, hue.toDouble(), saturationV, value);

  HSLColor get hsl =>
      HSLColor.fromAHSL(opacity, hue.toDouble(), saturationL, light);

  CMYKColor get cmyk =>
      CMYKColor.fromCMYK(cyan, magenta, yellow, black, opacity);

  String get string => '#${bitValue.toRadixString(16)}';

  @override
  String toString() => string;

  const WideColor._(
      {required this.bitValue,
      required this.hue,
      required this.value,
      required this.saturationV,
      required this.light,
      required this.saturationL,
      required this.black});

  WideColor._complete(Color color, HSVColor hsv, HSLColor hsl)
      : this._(
            bitValue: color.value,
            hue: hsv.hue.toInt(),
            value: hsv.value,
            saturationV: hsv.saturation,
            light: hsl.lightness,
            saturationL: hsl.saturation,
            black: 1 - [color.red, color.green, color.blue].reduce(max) / bit);

  WideColor._completeV(Color color, HSVColor hsv)
      : this._complete(color, hsv, HSLColor.fromColor(color));

  WideColor._completeL(Color color, HSLColor hsl)
      : this._complete(color, HSVColor.fromColor(color), hsl);

  WideColor.fromColor(Color color)
      : this._complete(
            color, HSVColor.fromColor(color), HSLColor.fromColor(color));

  WideColor.fromBitValue(int bitValue) : this.fromColor(Color(bitValue));

  WideColor.fromRGB(int r, int g, int b, {int? alpha, double? opacity})
      : this.fromColor(opacity != null
            ? Color.fromRGBO(r, g, b, opacity)
            : Color.fromARGB(alpha ?? bit, r, g, b));

  WideColor.fromHSVColor(HSVColor color)
      : this._completeV(color.toColor(), color);

  WideColor.fromHSV(int h, double s, double v, {int? alpha, double? opacity})
      : this.fromHSVColor(HSVColor.fromAHSV(
            alpha != null ? alpha / bit : opacity ?? 1.0, h.toDouble(), s, v));

  WideColor.fromHSLColor(HSLColor color)
      : this._completeL(color.toColor(), color);

  WideColor.fromHSL(int h, double s, double l, {int? alpha, double? opacity})
      : this.fromHSLColor(HSLColor.fromAHSL(
            alpha != null ? alpha / bit : opacity ?? 1.0, h.toDouble(), s, l));

  WideColor.fromCMYK(double c, double m, double y, double k,
      {int? alpha, double? opacity})
      : this.fromCMYKColor(CMYKColor.fromCMYK(
            c, m, y, k, alpha != null ? alpha / bit : opacity ?? 1));

  WideColor.fromCMYKColor(CMYKColor color) : this.fromColor(color.toColor());

  WideColor.fromString(String value)
      : this.fromColor(Color(int.parse(
            value.startsWith('0x')
                ? value.substring(2)
                : value.startsWith('#')
                    ? value.substring(1)
                    : value,
            radix: 16)));

  ToolColor withAlpha(int alpha) => ToolColor.fromColor(color.withAlpha(alpha));

  WideColor withOpacity(double opacity) => withAlpha((bit * opacity).round());

  WideColor withRGB(
          {int? red, int? green, int? blue, int? alpha, double? opacity}) =>
      WideColor.fromRGB(red ?? this.red, green ?? this.green, blue ?? this.blue,
          alpha:
              opacity != null ? (opacity * bit).round() : alpha ?? this.alpha);

  WideColor withRed(int red) => withRGB(red: red);
  WideColor withGreen(int green) => withRGB(green: green);
  WideColor withBlue(int blue) => withRGB(blue: blue);

  WideColor withHSV(
          {int? hue,
          double? saturation,
          double? value,
          int? alpha,
          double? opacity}) =>
      WideColor.fromHSV(
          hue ?? this.hue, saturation ?? saturationV, value ?? this.value,
          alpha:
              opacity != null ? (opacity * bit).round() : alpha ?? this.alpha);

  WideColor withHue(int hue) => withHSV(hue: hue);
  WideColor withSaturationV(double saturation) =>
      withHSV(saturation: saturation);
  WideColor withValue(double value) => withHSV(value: value);

  WideColor withHSL(
          {int? hue,
          double? saturation,
          double? light,
          int? alpha,
          double? opacity}) =>
      WideColor.fromHSL(
          hue ?? this.hue, saturation ?? saturationV, light ?? this.light,
          alpha:
              opacity != null ? (opacity * bit).round() : alpha ?? this.alpha);

  WideColor withSaturationL(double saturation) =>
      withHSL(saturation: saturation);
  WideColor withLight(double light) => withHSL(light: light);

  WideColor withCMYK(
          {double? cyan,
          double? magenta,
          double? yellow,
          double? black,
          int? alpha,
          double? opacity}) =>
      WideColor.fromCMYK(cyan ?? this.cyan, magenta ?? this.magenta,
          yellow ?? this.yellow, black ?? this.black,
          alpha:
              opacity != null ? (opacity * bit).round() : alpha ?? this.alpha);

  WideColor withcyan(double cyan) => withCMYK(cyan: cyan);
  WideColor withMagenta(double magenta) => withCMYK(magenta: magenta);
  WideColor withYellow(double yellow) => withCMYK(yellow: yellow);
  WideColor withBlack(double black) => withCMYK(black: black);

  WideColor copy() => WideColor._(
      bitValue: bitValue,
      hue: hue,
      value: value,
      saturationV: saturationV,
      light: light,
      saturationL: saturationL,
      black: black);

  ToolColor toTool() => ToolColor.fromColor(color);
  WideColor toWide() => copy();

  factory WideColor.mix(WideColor a, WideColor b,
      {double aInfluence = 0.5, ColorSource source = defaultColorSource}) {
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
  WideColor mix(WideColor other,
          {double otherInfluence = 0.5,
          ColorSource source = defaultColorSource}) =>
      WideColor.mix(other, this, aInfluence: otherInfluence, source: source);

  /// Calculates the luminance of this color.
  ///
  /// Returns the relative luminance of the color, which is essential for
  /// determining color contrast in accessibility guidelines.
  num get luminance => getLuminance(this);

  /// Calculates the contrast ratio between this color and [other].
  ///
  /// Returns the contrast ratio, which helps in determining the readability
  /// and accessibility of text against the background color.
  num contrast(WideColor other) => getContrast(this, other);

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
  }) =>
      asureContrast(this, other,
          preference: preference, minContrast: minContrast);
}

/// Write and read color which handles RGB, HSV, HSL, CMYK, Alpha, Opacity and Contrast
///
/// Use [WideColor] for const and read only
class ToolColor implements WideColor {
  static WideColor asureLightContrast(WideColor base, WideColor toContrast,
          {num minContrast = 4.5}) =>
      WideColor.asureDarkContrast(base, toContrast, minContrast: minContrast);

  static WideColor asureDarkContrast(WideColor base, WideColor toContrast,
          {num minContrast = 4.5}) =>
      WideColor.asureDarkContrast(base, toContrast, minContrast: minContrast);

  /// Adjust the [toContrast] color to ensure a minimum contrast ratio against [base].
  /// This method will adjust the color based on the [preference] for light or dark contrast.
  /// If [preference] is [ContrastPreference.free], it will choose the adjustment
  /// based on the relative luminance of the colors.
  static WideColor asureContrast(WideColor base, WideColor toContrast,
          {num minContrast = 4.5,
          ContrastPreference preference = defaultContrastPreference}) =>
      WideColor.asureContrast(base, toContrast,
          minContrast: minContrast, preference: preference);

  static num getLuminance(WideColor color) => WideColor.getLuminance(color);

  /// Calculate the contrast ratio between two [WideColor] instances [a] and [b].
  /// This follows the WCAG 2.0 guidelines for contrast ratios:
  /// - 3:1 for large text (at least 18pt or 14pt bold)
  /// - 4.5:1 for normal text
  /// - 7:1 for enhanced accessibility
  static num getContrast(WideColor a, WideColor b) =>
      WideColor.getContrast(a, b);

  Color? _color;
  HSVColor? _hsv;
  HSLColor? _hsl;
  CMYKColor? _cmyk;

  @override
  int get bitValue => color.value;
  set bitValue(int value) => color = Color(value);

  @override
  int get alpha => color.alpha;
  set alpha(int value) => color = color.withAlpha(value);

  @override
  double get opacity => alpha / bit;
  set opacity(double value) => alpha = (value * bit).round();

  @override
  int get red => color.red;
  set red(int value) => color = color.withRed(value);

  @override
  int get green => color.green;
  set green(int value) => color = color.withGreen(value);

  @override
  int get blue => color.blue;
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
  set cyan(double value) => cmyk = cmyk.withcyan(value);

  @override
  double get magenta => cmyk.magenta;
  set magenta(double value) => cmyk = cmyk.withMagetna(value);

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
  Color get color => _color ??= _hsv?.toColor() ??
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
  String get string => '#${bitValue.toRadixString(16)}';
  set string(String value) => color = Color(int.parse(
      value.startsWith('0x')
          ? value.substring(2)
          : value.startsWith('#')
              ? value.substring(1)
              : value,
      radix: 16));

  @override
  String toString() => string;

  ToolColor.fromColor(Color color) : _color = color;

  ToolColor.fromBitValue(int bitValue) : this.fromColor(Color(bitValue));

  ToolColor.fromRGB(int r, int g, int b, {int? alpha, double? opacity})
      : this.fromColor(opacity != null
            ? Color.fromRGBO(r, g, b, opacity)
            : Color.fromARGB(alpha ?? bit, r, g, b));
  ToolColor.fromHSVColor(HSVColor color) : _hsv = color;

  ToolColor.fromHSV(int h, double s, double v, {int? alpha, double? opacity})
      : this.fromHSVColor(HSVColor.fromAHSV(
            alpha != null ? alpha / bit : opacity ?? 1.0, h.toDouble(), s, v));

  ToolColor.fromHSLColor(HSLColor color) : _hsl = color;

  ToolColor.fromHSL(int h, double s, double l, {int? alpha, double? opacity})
      : this.fromHSLColor(HSLColor.fromAHSL(
            alpha != null ? alpha / bit : opacity ?? 1.0, h.toDouble(), s, l));

  ToolColor.fromCMYK(double c, double m, double y, double k,
      {int? alpha, double? opacity})
      : this.fromCMYKColor(CMYKColor.fromCMYK(
            c, m, y, k, alpha != null ? alpha / bit : opacity ?? 1));

  ToolColor.fromCMYKColor(CMYKColor color) : this.fromColor(color.toColor());

  ToolColor.fromString(String value)
      : this.fromColor(Color(int.parse(
            value.startsWith('0x')
                ? value.substring(2)
                : value.startsWith('#')
                    ? value.substring(1)
                    : value,
            radix: 16)));

  @override
  ToolColor withAlpha(int alpha) => ToolColor.fromColor(color.withAlpha(alpha));

  @override
  ToolColor withOpacity(double opacity) => withAlpha((bit * opacity).round());

  @override
  ToolColor withRGB(
          {int? red, int? green, int? blue, int? alpha, double? opacity}) =>
      ToolColor.fromRGB(red ?? this.red, green ?? this.green, blue ?? this.blue,
          alpha:
              opacity != null ? (opacity * bit).round() : alpha ?? this.alpha);

  @override
  ToolColor withRed(int red) => withRGB(red: red);
  @override
  ToolColor withGreen(int green) => withRGB(green: green);
  @override
  ToolColor withBlue(int blue) => withRGB(blue: blue);

  @override
  ToolColor withHSV(
          {int? hue,
          double? saturation,
          double? value,
          int? alpha,
          double? opacity}) =>
      ToolColor.fromHSV(
          hue ?? this.hue, saturation ?? saturationV, value ?? this.value,
          alpha:
              opacity != null ? (opacity * bit).round() : alpha ?? this.alpha);

  @override
  ToolColor withHue(int hue) => withHSV(hue: hue);
  @override
  ToolColor withSaturationV(double saturation) =>
      withHSV(saturation: saturation);
  @override
  ToolColor withValue(double value) => withHSV(value: value);

  @override
  ToolColor withHSL(
          {int? hue,
          double? saturation,
          double? light,
          int? alpha,
          double? opacity}) =>
      ToolColor.fromHSL(
          hue ?? this.hue, saturation ?? saturationV, light ?? this.light,
          alpha:
              opacity != null ? (opacity * bit).round() : alpha ?? this.alpha);

  @override
  ToolColor withSaturationL(double saturation) =>
      withHSL(saturation: saturation);
  @override
  ToolColor withLight(double light) => withHSL(light: light);

  @override
  ToolColor withCMYK(
          {double? cyan,
          double? magenta,
          double? yellow,
          double? black,
          int? alpha,
          double? opacity}) =>
      ToolColor.fromCMYK(cyan ?? this.cyan, magenta ?? this.magenta,
          yellow ?? this.yellow, black ?? this.black,
          alpha:
              opacity != null ? (opacity * bit).round() : alpha ?? this.alpha);

  @override
  ToolColor withcyan(double cyan) => withCMYK(cyan: cyan);
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

  factory ToolColor.mix(WideColor a, WideColor b,
      {double aInfluence = 0.5, ColorSource source = defaultColorSource}) {
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
  ToolColor mix(WideColor other,
          {double otherInfluence = 0.5,
          ColorSource source = defaultColorSource}) =>
      ToolColor.mix(other, this, aInfluence: otherInfluence, source: source);

  @override
  num get luminance => getLuminance(this);

  @override
  num contrast(WideColor other) => getContrast(this, other);

  @override
  WideColor fixContrast(
    WideColor other, {
    num minContrast = 4.5,
    ContrastPreference preference = defaultContrastPreference,
  }) =>
      asureContrast(this, other,
          preference: preference, minContrast: minContrast);
}

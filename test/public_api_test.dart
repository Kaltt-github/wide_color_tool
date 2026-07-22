import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wide_color_tool/wide_color_tool.dart';

void main() {
  group('public helpers and representations', () {
    test('clamps normalized percentages to an 8-bit channel', () {
      expect(percentageToBit(-0.1), 0);
      expect(percentageToBit(0.5), 128);
      expect(percentageToBit(1.1), maxBit);
    });

    test('formats WideColor with the requested prefix', () {
      final color = WideColor.fromString('#01020A0F');

      expect(color.toString(), '#01020A0F');
      expect(color.toString('0x'), '0x01020A0F');
      expect(color.toString(''), '01020A0F');
      expect(color.string, '#01020A0F');
    });

    test('formats ToolColor with the requested prefix', () {
      final color = ToolColor.fromString('#01020A0F');

      expect(color.toString(), '#01020A0F');
      expect(color.toString('0x'), '0x01020A0F');
      expect(color.toString(''), '01020A0F');
      expect(color.string, '#01020A0F');
    });
  });

  group('WideColor construction and transformations', () {
    test('constructs equivalent colors from every supported color space', () {
      const material = Color(0x80336699);
      final hsv = HSVColor.fromColor(material);
      final hsl = HSLColor.fromColor(material);
      final cmyk = CMYKColor.fromColor(material);

      expect(WideColor.fromColor(material).bitValue, material.toARGB32());
      expect(WideColor.fromBitValue(0x80336699).bitValue, 0x80336699);
      expect(WideColor.fromRGB(51, 102, 153, alpha: 128).alpha, 128);
      expect(WideColor.fromRGB(51, 102, 153, opacity: 0.5).alpha, 128);
      expect(WideColor.fromHSVColor(hsv).color.toARGB32(), material.toARGB32());
      expect(WideColor.fromHSLColor(hsl).color.toARGB32(), material.toARGB32());
      expect(
        WideColor.fromCMYKColor(cmyk).color.toARGB32(),
        material.toARGB32(),
      );
      expect(WideColor.fromHSV(210, 2 / 3, 0.6, alpha: 128).alpha, 128);
      expect(WideColor.fromHSV(210, 2 / 3, 0.6, opacity: 0.5).alpha, 128);
      expect(WideColor.fromHSL(210, 0.5, 0.4, alpha: 128).alpha, 128);
      expect(WideColor.fromHSL(210, 0.5, 0.4, opacity: 0.5).alpha, 128);
      expect(WideColor.fromCMYK(2 / 3, 1 / 3, 0, 0.4, alpha: 128).alpha, 128);
      expect(WideColor.fromCMYK(2 / 3, 1 / 3, 0, 0.4, opacity: 0.5).alpha, 128);
    });

    test('exposes consistent derived representations', () {
      final color = WideColor.fromString('#80336699');

      expect(color.color.toARGB32(), color.bitValue);
      expect(color.hsv.toColor().toARGB32(), color.bitValue);
      expect(color.hsl.toColor().toARGB32(), color.bitValue);
      expect(color.cmyk.toColor().toARGB32(), color.bitValue);
      expect(color.key, color.black);
      expect(color.toWide(), equals(color));
      expect(color.toWide(), isNot(same(color)));
      expect(color.copy(), equals(color));
      expect(color.toTool().bitValue, color.bitValue);
    });

    test('changes RGB and opacity channels independently', () {
      final color = WideColor.fromString('#80402010');

      expect(color.withOpacity(0.25).alpha, 64);
      expect(
        color.withRGB(red: 1, green: 2, blue: 3, alpha: 4).bitValue,
        0x04010203,
      );
      expect(color.withRGB(opacity: 0.5).alpha, 128);
      expect(color.withRed(8).red, 8);
      expect(color.withGreen(9).green, 9);
      expect(color.withBlue(10).blue, 10);
    });

    test('changes HSV and HSL channels independently', () {
      final color = WideColor.fromHSV(180, 0.5, 0.5, alpha: 200);

      expect(color.withHSV(hue: 90, saturation: 0.4, value: 0.6).hue, 90);
      expect(color.withHSV(opacity: 0.25).alpha, 64);
      expect(color.withHue(120).hue, 120);
      expect(color.withSaturationV(0.2).saturationV, closeTo(0.2, 0.001));
      expect(color.withValue(0.7).value, closeTo(0.7, 0.001));

      final hsl = color.withHSL(hue: 60, saturation: 0.3, light: 0.4);
      expect(hsl.hue, 60);
      expect(hsl.saturationL, closeTo(0.3, 0.001));
      expect(hsl.light, closeTo(0.4, 0.001));
      expect(color.withHSL(opacity: 0.25).alpha, 64);
      expect(color.withSaturationL(0.25).saturationL, closeTo(0.25, 0.001));
      expect(color.withLight(0.3).light, closeTo(0.3, 0.001));
    });

    test('changes CMYK channels independently', () {
      final color = WideColor.fromCMYK(0.1, 0.2, 0.3, 0.1, alpha: 200);

      expect(
        color.withCMYK(cyan: 0.4).bitValue,
        WideColor.fromCMYK(
          0.4,
          color.magenta,
          color.yellow,
          color.black,
          alpha: color.alpha,
        ).bitValue,
      );
      expect(color.withCMYK(opacity: 0.25).alpha, 64);
      expect(color.withCyan(0.2), color.withCMYK(cyan: 0.2));
      expect(color.withMagenta(0.3), color.withCMYK(magenta: 0.3));
      expect(color.withYellow(0.4), color.withCMYK(yellow: 0.4));
      expect(color.withBlack(0.2), color.withCMYK(black: 0.2));
    });

    test('mixes through every color source', () {
      final first = WideColor.fromString('#80FF0000');
      final second = WideColor.fromString('#400000FF');

      for (final source in ColorSource.values) {
        final mixed = WideColor.mix(first, second, source: source);
        final instanceMixed = first.mix(second, source: source);

        expect(mixed, isA<WideColor>());
        expect(instanceMixed, isA<WideColor>());
        expect(mixed.alpha, closeTo(96, 1));
      }
      expect(
        () => WideColor.mix(first, second, aInfluence: -0.1),
        throwsRangeError,
      );
      expect(
        () => WideColor.mix(first, second, aInfluence: 1.1),
        throwsRangeError,
      );
    });
  });

  group('ToolColor mutable API', () {
    test('constructs from every color space', () {
      const material = Color(0x80336699);
      final colors = <ToolColor>[
        ToolColor.fromColor(material),
        ToolColor.fromBitValue(0x80336699),
        ToolColor.fromRGB(51, 102, 153, alpha: 128),
        ToolColor.fromRGB(51, 102, 153, opacity: 0.5),
        ToolColor.fromHSVColor(HSVColor.fromColor(material)),
        ToolColor.fromHSV(210, 2 / 3, 0.6, alpha: 128),
        ToolColor.fromHSV(210, 2 / 3, 0.6, opacity: 0.5),
        ToolColor.fromHSLColor(HSLColor.fromColor(material)),
        ToolColor.fromHSL(210, 0.5, 0.4, alpha: 128),
        ToolColor.fromHSL(210, 0.5, 0.4, opacity: 0.5),
        ToolColor.fromCMYKColor(CMYKColor.fromColor(material)),
        ToolColor.fromCMYK(2 / 3, 1 / 3, 0, 0.4, alpha: 128),
        ToolColor.fromCMYK(2 / 3, 1 / 3, 0, 0.4, opacity: 0.5),
      ];

      for (final color in colors) {
        expect(color.alpha, closeTo(128, 1));
      }
    });

    test('mutates scalar and representation properties', () {
      final color = ToolColor.fromRGB(10, 20, 30);

      color
        ..bitValue = 0x80402010
        ..alpha = 200
        ..opacity = 0.5
        ..red = 40
        ..green = 50
        ..blue = 60
        ..hue = 120
        ..value = 0.7
        ..saturationV = 0.4
        ..light = 0.4
        ..saturationL = 0.3
        ..cyan = 0.2
        ..magenta = 0.3
        ..yellow = 0.4
        ..black = 0.1
        ..key = 0.2;

      expect(color.alpha, 128);
      expect(color.hue, inInclusiveRange(0, 360));
      expect(color.key, closeTo(0.2, 0.01));

      color.color = const Color(0xFF112233);
      expect(color.bitValue, 0xFF112233);
      color.hsv = HSVColor.fromAHSV(1, 30, 0.5, 0.5);
      expect(color.hue, 30);
      color.hsl = HSLColor.fromAHSL(1, 60, 0.5, 0.5);
      expect(color.hue, 60);
      color.cmyk = const CMYKColor.fromCMYK(0.1, 0.2, 0.3, 0.4, 1);
      expect(color.cyan, closeTo(0.1, 0.001));
    });

    test('returns mutable copies from every with operation', () {
      final color = ToolColor.fromString('#80402010');
      final variants = <ToolColor>[
        color.withAlpha(1),
        color.withOpacity(0.5),
        color.withRGB(red: 1, green: 2, blue: 3, opacity: 0.5),
        color.withRed(1),
        color.withGreen(2),
        color.withBlue(3),
        color.withHSV(hue: 30, saturation: 0.5, value: 0.6, opacity: 0.5),
        color.withHue(60),
        color.withSaturationV(0.4),
        color.withValue(0.7),
        color.withHSL(hue: 90, saturation: 0.4, light: 0.5, opacity: 0.5),
        color.withSaturationL(0.3),
        color.withLight(0.6),
        color.withCMYK(
          cyan: 0.1,
          magenta: 0.2,
          yellow: 0.3,
          black: 0.1,
          opacity: 0.5,
        ),
        color.withCyan(0.2),
        color.withMagenta(0.3),
        color.withYellow(0.4),
        color.withBlack(0.2),
        color.copy(),
        color.toTool(),
      ];

      for (final variant in variants) {
        expect(variant, isA<ToolColor>());
        expect(variant, isNot(same(color)));
      }
      expect(color.toWide(), isA<WideColor>());
      expect(color.toWide(), isNot(isA<ToolColor>()));
    });

    test('mixes through every source and validates influence', () {
      final first = ToolColor.fromString('#80FF0000');
      final second = ToolColor.fromString('#400000FF');

      for (final source in ColorSource.values) {
        expect(ToolColor.mix(first, second, source: source), isA<ToolColor>());
        expect(first.mix(second, source: source), isA<ToolColor>());
      }
      expect(
        () => ToolColor.mix(first, second, aInfluence: -0.1),
        throwsRangeError,
      );
      expect(
        () => ToolColor.mix(first, second, aInfluence: 1.1),
        throwsRangeError,
      );
    });
  });

  group('contrast edge cases', () {
    final black = WideColor.fromRGB(0, 0, 0);
    final white = WideColor.fromRGB(255, 255, 255);

    test('returns an already compliant color unchanged', () {
      expect(WideColor.ensureContrast(black, white), same(white));
      expect(WideColor.ensureLightContrast(black, white), same(white));
      expect(WideColor.ensureDarkContrast(white, black), same(black));
      expect(
        WideColor.ensureContrast(
          black,
          WideColor.fromRGB(30, 30, 30),
          preference: ContrastPreference.light,
        ).contrast(black),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        WideColor.ensureContrast(
          white,
          WideColor.fromRGB(220, 220, 220),
          preference: ContrastPreference.dark,
        ).contrast(white),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('supports free adjustment and unreachable endpoints', () {
      final adjusted = WideColor.ensureContrast(
        WideColor.fromRGB(128, 128, 128),
        WideColor.fromRGB(130, 130, 130),
        minContrast: 7,
      );
      expect(
        adjusted,
        anyOf(WideColor.fromRGB(0, 0, 0), WideColor.fromRGB(255, 255, 255)),
      );
    });

    test('delegates ToolColor contrast helpers and instance methods', () {
      final mutable = ToolColor.fromRGB(0, 0, 0);
      expect(ToolColor.getLuminance(mutable), mutable.luminance);
      expect(ToolColor.getContrast(mutable, white), closeTo(21, 0.000001));
      expect(mutable.contrast(white), closeTo(21, 0.000001));
      expect(
        ToolColor.ensureDarkContrast(white, white).contrast(white),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ToolColor.ensureContrast(
          mutable,
          WideColor.fromRGB(20, 20, 20),
          preference: ContrastPreference.light,
        ).contrast(mutable),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        mutable.fixContrast(white, minContrast: 7).contrast(mutable),
        greaterThanOrEqualTo(7),
      );
    });

    test('rejects contrast ratios below and above the WCAG range', () {
      expect(
        () => WideColor.ensureContrast(black, white, minContrast: 0.9),
        throwsRangeError,
      );
      expect(
        () => WideColor.ensureContrast(black, white, minContrast: 21.1),
        throwsRangeError,
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wide_color_tool/wide_color_tool.dart';

void main() {
  group('CMYKColor', () {
    test('round-trips an RGB color', () {
      const source = Color(0xFF336699);

      final cmyk = CMYKColor.fromColor(source);

      expect(cmyk.toColor().toARGB32(), source.toARGB32());
    });

    test('represents pure black without undefined components', () {
      final cmyk = CMYKColor.fromColor(const Color(0xFF000000));

      expect(cmyk.cyan, 0);
      expect(cmyk.magenta, 0);
      expect(cmyk.yellow, 0);
      expect(cmyk.black, 1);
    });

    test('updates the requested component', () {
      const color = CMYKColor.fromCMYK(0.1, 0.2, 0.3, 0.4, 1);

      expect(color.withCyan(0.8).cyan, 0.8);
      expect(color.withMagenta(0.7).magenta, 0.7);
      expect(color.withYellow(0.6).yellow, 0.6);
      expect(color.withBlack(0.5).black, 0.5);
    });

    test('interpolates every component linearly', () {
      const start = CMYKColor.fromCMYK(0, 0.2, 0.4, 0.6, 0.8);
      const end = CMYKColor.fromCMYK(1, 0.8, 0.6, 0.4, 0.2);

      final midpoint = start.lerp(end, 0.5);

      expect(midpoint, const CMYKColor.fromCMYK(0.5, 0.5, 0.5, 0.5, 0.5));
      expect(() => start.lerp(end, 1.1), throwsRangeError);
    });
  });

  group('hexadecimal colors', () {
    test('accepts common RGB and ARGB notations', () {
      expect(WideColor.fromString('#F0A').bitValue, 0xFFFF00AA);
      expect(WideColor.fromString('#8F0A').bitValue, 0x88FF00AA);
      expect(WideColor.fromString('336699').bitValue, 0xFF336699);
      expect(WideColor.fromString('0x80336699').bitValue, 0x80336699);
    });

    test('formats a padded uppercase ARGB value', () {
      expect(WideColor.fromBitValue(0x01020A0F).string, '#01020A0F');
    });

    test('rejects malformed input', () {
      expect(() => WideColor.fromString('#12'), throwsFormatException);
      expect(() => WideColor.fromString('#GGG'), throwsFormatException);
    });
  });

  group('WideColor', () {
    test('keeps immutable operations immutable', () {
      final color = WideColor.fromRGB(1, 2, 3);

      final changed = color.withAlpha(128);

      expect(changed, isA<WideColor>());
      expect(changed, isNot(isA<ToolColor>()));
      expect(changed.alpha, 128);
      expect(color.alpha, 255);
    });

    test('preserves HSL saturation when changing lightness', () {
      final color = WideColor.fromRGB(64, 128, 192);

      final changed = color.withLight(0.7);

      expect(changed.saturationL, closeTo(color.saturationL, 0.000001));
    });

    test('compares immutable colors by ARGB value', () {
      final wide = WideColor.fromRGB(1, 2, 3);
      final sameWide = WideColor.fromString('#010203');
      final mutable = ToolColor.fromString('#010203');

      expect(wide, sameWide);
      expect(wide.hashCode, sameWide.hashCode);
      expect(wide == mutable, isFalse);
      expect(mutable == wide, isFalse);
    });

    test('validates color mixing influence', () {
      final red = WideColor.fromRGB(255, 0, 0);
      final blue = WideColor.fromRGB(0, 0, 255);

      expect(red.mix(blue, otherInfluence: 0), red);
      expect(red.mix(blue, otherInfluence: 1), blue);
      expect(() => red.mix(blue, otherInfluence: 1.1), throwsRangeError);
    });
  });

  group('contrast', () {
    final black = WideColor.fromRGB(0, 0, 0);
    final white = WideColor.fromRGB(255, 255, 255);

    test('uses the WCAG luminance ordering', () {
      expect(black.contrast(white), closeTo(21, 0.000001));
      expect(white.contrast(black), closeTo(21, 0.000001));
      expect(
        WideColor.fromRGB(0, 255, 0).contrast(WideColor.fromRGB(0, 0, 255)),
        greaterThan(1),
      );
    });

    test('finds lighter and darker accessible alternatives', () {
      final darkGray = WideColor.fromRGB(40, 40, 40);
      final lightGray = WideColor.fromRGB(210, 210, 210);

      final lighter = WideColor.ensureLightContrast(
        black,
        darkGray,
        minContrast: 4.5,
      );
      final darker = WideColor.ensureDarkContrast(
        white,
        lightGray,
        minContrast: 4.5,
      );

      expect(black.contrast(lighter), greaterThanOrEqualTo(4.5));
      expect(white.contrast(darker), greaterThanOrEqualTo(4.5));
      expect(lighter.red, greaterThan(darkGray.red));
      expect(darker.red, lessThan(lightGray.red));
    });

    test('ToolColor delegates light adjustment correctly', () {
      final adjusted = ToolColor.ensureLightContrast(
        black,
        WideColor.fromRGB(20, 20, 20),
      );

      expect(adjusted.red, greaterThan(20));
      expect(black.contrast(adjusted), greaterThanOrEqualTo(4.5));
    });

    test('validates the requested ratio', () {
      expect(
        () => WideColor.ensureContrast(black, white, minContrast: 22),
        throwsRangeError,
      );
    });
  });

  group('ToolColor', () {
    test('updates CMYK channels independently', () {
      final color = ToolColor.fromCMYK(0.1, 0.2, 0.3, 0.4);

      color.magenta = 0.8;

      expect(color.magenta, closeTo(0.8, 0.000001));
      expect(color.yellow, closeTo(0.3, 0.000001));
    });

    test('parses opaque RGB strings through the mutable setter', () {
      final color = ToolColor.fromRGB(0, 0, 0)..string = '#ABCDEF';

      expect(color.bitValue, 0xFFABCDEF);
    });
  });
}

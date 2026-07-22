import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wide_color_tool/wide_color_tool.dart';

void main() {
  group('representation invariants', () {
    test('representative ARGB values survive every conversion round-trip', () {
      const channels = <int>[0, 1, 127, 128, 254, 255];

      for (final alpha in channels) {
        for (final red in channels) {
          for (final green in channels) {
            for (final blue in channels) {
              final color = WideColor.fromRGB(red, green, blue, alpha: alpha);

              expect(color.color.toARGB32(), color.bitValue);
              expect(color.hsv.toColor().toARGB32(), color.bitValue);
              expect(color.hsl.toColor().toARGB32(), color.bitValue);
              expect(color.cmyk.toColor().toARGB32(), color.bitValue);
              expect(color.hueDegrees, color.hsv.hue);
              expect(WideColor.fromString(color.string), color);
              final toolColor = color.toTool();
              expect(toolColor.hueDegrees, toolColor.hsv.hue);
              expect(toolColor.toWide(), color);
            }
          }
        }
      }
    });

    test(
      'mixing endpoints preserve the selected input in every color space',
      () {
        final first = WideColor.fromString('#80336699');
        final second = WideColor.fromString('#40CC8844');

        for (final source in ColorSource.values) {
          expect(
            WideColor.mix(first, second, aInfluence: 1, source: source),
            first,
            reason: 'first WideColor endpoint in $source',
          );
          expect(
            WideColor.mix(first, second, aInfluence: 0, source: source),
            second,
            reason: 'second WideColor endpoint in $source',
          );
          expect(
            ToolColor.mix(
              first,
              second,
              aInfluence: 1,
              source: source,
            ).bitValue,
            first.bitValue,
            reason: 'first ToolColor endpoint in $source',
          );
          expect(
            ToolColor.mix(
              first,
              second,
              aInfluence: 0,
              source: source,
            ).bitValue,
            second.bitValue,
            reason: 'second ToolColor endpoint in $source',
          );
        }
      },
    );
  });

  group('comparison invariants', () {
    test(
      'WideColor equality covers identity, value, type, and mismatch paths',
      () {
        final color = WideColor.fromString('#FF336699');
        final equal = WideColor.fromString('#FF336699');
        final different = WideColor.fromString('#FF336698');

        expect(color == color, isTrue);
        expect(color == equal, isTrue);
        expect(color.hashCode, equal.hashCode);
        expect(color == different, isFalse);
        expect(color == color.toTool(), isFalse);
        expect(color == (const Color(0xFF336699) as Object), isFalse);
      },
    );

    test('contrast is symmetric and remains within the WCAG ratio range', () {
      final colors = <WideColor>[
        WideColor.fromRGB(0, 0, 0),
        WideColor.fromRGB(1, 1, 1),
        WideColor.fromRGB(64, 128, 192),
        WideColor.fromRGB(128, 128, 128),
        WideColor.fromRGB(254, 254, 254),
        WideColor.fromRGB(255, 255, 255),
      ];

      for (final first in colors) {
        for (final second in colors) {
          final ratio = first.contrast(second);
          expect(ratio, inInclusiveRange(1, 21));
          expect(ratio, closeTo(second.contrast(first), 0.000001));
        }
      }
    });
  });

  group('contrast decision paths', () {
    final black = WideColor.fromRGB(0, 0, 0);
    final white = WideColor.fromRGB(255, 255, 255);

    test('free preference selects the only reachable direction', () {
      final light = WideColor.ensureContrast(
        black,
        WideColor.fromRGB(20, 20, 20),
      );
      final dark = WideColor.ensureContrast(
        white,
        WideColor.fromRGB(235, 235, 235),
      );

      expect(light.red, greaterThan(20));
      expect(light.contrast(black), greaterThanOrEqualTo(4.5));
      expect(dark.light, lessThan(0.5));
      expect(dark.contrast(white), greaterThanOrEqualTo(4.5));
    });

    test('free preference chooses the closest unreachable endpoint', () {
      final middle = WideColor.fromRGB(128, 128, 128);

      expect(
        WideColor.ensureContrast(
          middle,
          WideColor.fromRGB(130, 130, 130),
          minContrast: 7,
        ),
        white,
      );
      expect(
        WideColor.ensureContrast(
          middle,
          WideColor.fromRGB(126, 126, 126),
          minContrast: 7,
        ),
        black,
      );
    });
  });
}

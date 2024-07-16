import 'dart:math';
import 'dart:ui';

const bit = 0XFF;

class CMYKColor {
  /// `[0.0..1.0]`
  final double cian;

  /// `[0.0..1.0]`
  final double magenta;

  /// `[0.0..1.0]`
  final double yellow;

  /// `[0.0..1.0]`
  final double black;

  /// `[0.0..1.0]`
  final double opacity;

  const CMYKColor.fromCMYK(
      this.cian, this.magenta, this.yellow, this.black, this.opacity)
      : assert(0 <= cian, cian <= 1),
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
      (255 * (1 - cian) * (1 - black)).round(),
      (255 * (1 - magenta) * (1 - black)).round(),
      (255 * (1 - yellow) * (1 - black)).round(),
      opacity);

  CMYKColor withCian(double cian) =>
      CMYKColor.fromCMYK(cian, magenta, yellow, black, opacity);

  CMYKColor withMagetna(double yellow) =>
      CMYKColor.fromCMYK(cian, magenta, yellow, black, opacity);

  CMYKColor withYellow(double yellow) =>
      CMYKColor.fromCMYK(cian, magenta, yellow, black, opacity);

  CMYKColor withBlack(double black) =>
      CMYKColor.fromCMYK(cian, magenta, yellow, black, opacity);

  /// Linearly interpolates between this color and another CMYKColor.
  CMYKColor lerp(CMYKColor other, double t) => CMYKColor.fromCMYK(
        cian * (1 - t) + (other.cian - cian) * t,
        magenta * (1 - t) + (other.magenta - cian) * t,
        yellow * (1 - t) + (other.yellow - cian) * t,
        black * (1 - t) + (other.black - cian) * t,
        opacity * (1 - t) + (other.opacity - cian) * t,
      );
}

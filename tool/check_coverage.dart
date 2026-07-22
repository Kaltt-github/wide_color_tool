import 'dart:io';

void main(List<String> arguments) {
  final minimum = arguments.isEmpty ? 80.0 : double.parse(arguments.single);
  final coverageFile = File('coverage/lcov.info');
  if (!coverageFile.existsSync()) {
    stderr.writeln(
      'Coverage report not found. Run `flutter test --coverage` first.',
    );
    exitCode = 2;
    return;
  }

  var foundLines = 0;
  var hitLines = 0;
  for (final line in coverageFile.readAsLinesSync()) {
    if (line.startsWith('LF:')) {
      foundLines += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hitLines += int.parse(line.substring(3));
    }
  }

  if (foundLines == 0) {
    stderr.writeln('The coverage report does not contain executable lines.');
    exitCode = 2;
    return;
  }

  final coverage = hitLines * 100 / foundLines;
  stdout.writeln(
    'Line coverage: ${coverage.toStringAsFixed(2)}% '
    '($hitLines/$foundLines; required: ${minimum.toStringAsFixed(2)}%)',
  );
  if (coverage < minimum) {
    stderr.writeln('Coverage is below the required threshold.');
    exitCode = 1;
  }
}

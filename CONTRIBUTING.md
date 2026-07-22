# Contributing

Thank you for improving `wide_color_tool`.

## Workflow

1. Create a branch from `main`.
2. Keep each change focused and add tests for behavior changes.
3. Run the complete local verification suite:

   ```sh
   flutter pub get
   dart format --output=none --set-exit-if-changed .
   flutter analyze
   flutter test
   ```

4. Use a [Conventional Commit](https://www.conventionalcommits.org/) message,
   such as `fix: correct CMYK interpolation`.
5. Open a pull request describing the problem, solution, and verification.

## Compatibility

Avoid breaking public APIs without discussion. When a rename is necessary,
prefer adding the corrected API and retaining a deprecated forwarding alias for
at least one major release.

## Reporting bugs

Open a GitHub issue with a minimal reproduction, expected behavior, actual
behavior, and the Flutter and Dart versions used.

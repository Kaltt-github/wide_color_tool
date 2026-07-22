## Summary

Describe the change and why it is needed.

## Verification

- [ ] `dart format --output=none --set-exit-if-changed .`
- [ ] `flutter analyze --fatal-infos`
- [ ] `flutter test --coverage`
- [ ] `dart run tool/check_coverage.dart 80`
- [ ] The example was updated if the public API or behavior changed.
- [ ] `CHANGELOG.md` was updated for a user-visible change.

## Compatibility

List any breaking changes, migrations, or platform-specific effects. Write
`None` when this change is backward compatible.

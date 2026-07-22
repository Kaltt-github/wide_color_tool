# Release process

This project follows Semantic Versioning. Releases are created from a clean
`main` branch after CI passes. Do not reuse or move an existing release tag.

## Prepare

1. Confirm that `pubspec.yaml` contains the intended version and that the same
   version has a dated section in `CHANGELOG.md`.
2. Update `.github/release-notes/v2.0.0.md` with the final user-facing summary.
3. Run the complete preflight from the repository root:

   ```sh
   dart format --output=none --set-exit-if-changed .
   flutter analyze --fatal-infos
   flutter test --coverage
   dart run tool/check_coverage.dart 100
   flutter --suppress-analytics pub publish --dry-run
   ```

4. Validate the independent example:

   ```sh
   cd example
   flutter pub get
   flutter analyze --fatal-infos
   flutter test
   flutter build web
   cd ..
   ```

5. Merge the prepared release changes into `main`, pull the exact remote state,
   and verify that the worktree is clean.

## Publish version 2.0.0

Run these commands only after the final approval to release:

```sh
git switch main
git pull --ff-only origin main
git tag -a v2.0.0 -m "wide_color_tool 2.0.0"
git push origin v2.0.0
gh release create v2.0.0 --verify-tag --title "wide_color_tool 2.0.0" --notes-file .github/release-notes/v2.0.0.md
dart pub publish
```

Publishing to pub.dev requires an account authorized for the package and an
interactive confirmation. After publishing, verify the package page, API docs,
GitHub Release, and installation in a new Flutter project.

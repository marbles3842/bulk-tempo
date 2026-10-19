# Lessons Learned

> Append-only register of recurring rules and patterns. Re-read at start by /10x-frame, /10x-research, /10x-plan, /10x-plan-review, /10x-implement, /10x-impl-review.

## Separate Dev Tooling and Component Catalogs from Production lib/

- **Context**: `pubspec.yaml:36`, `lib/widgetbook/main_widgetbook.dart:1`
- **Problem**: Declaring development-only dependencies (like `widgetbook`) under `dev_dependencies` while placing catalog source files inside `lib/` triggers `depend_on_referenced_packages` analyzer warnings and blurs the public library boundary of the app.
- **Rule**: Place standalone component catalogs, mock generators, and developer tooling outside `lib/` (e.g., in a root-level `widgetbook/` or `tool/` directory), or promote the package to runtime `dependencies` if kept inside `lib/`.
- **Applies to**: Dart and Flutter packages with dev-only catalogs or runner entrypoints.

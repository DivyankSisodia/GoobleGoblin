# Gooble Goblin Project Rules

## 1) Core Principles
- Keep the app stable first. No change should break existing user data, navigation flow, or payment/category rendering.
- Prefer small, reviewable changes over broad refactors.
- Always preserve current UI spacing, sizing, and behavior unless a UI change is explicitly requested.

## 2) Architecture Rules
- Follow existing layered structure:
  - `lib/core` for models, DB, shared utilities, theme/constants.
  - `lib/data/repositories` for data access logic.
  - `lib/features/...` for screen/widget logic.
  - `lib/providers` for Riverpod state wiring.
- Avoid business logic inside UI widgets when it can live in providers/repositories.
- Reuse existing models (`Payment`, `Category`, `BankCard`, settings models) instead of creating duplicate types.

## 3) Asset Rules (Strict)
- `assets/images/` is SVG-first for app category/payment icons.
- Use `flutter_svg` (`SvgPicture.asset`) for category/payment icon rendering.
- SVG requirements for icons:
  - Square `viewBox` (typically `0 0 24 24`).
  - `currentColor` for stroke/fill whenever dynamic tinting is needed.
  - No hardcoded colors except for intentionally multi-color decorative assets.
- Do not reintroduce `assets/images/*.png` references in Dart code.
- Do not touch platform app icons/splash assets unless explicitly requested:
  - Android/iOS/web/windows/macos launcher/splash resources are excluded by default.

## 4) Category Asset Compatibility Rules
- Legacy DB rows may contain `.png` paths; app must normalize these safely to `.svg`.
- Keep path normalization logic centralized in `Category.normalizeAssetPath(...)`.
- Any new read/write path flow for categories must pass through normalization.
- DB startup should include idempotent migration/repair for legacy asset paths.

## 5) UI Rendering Rules
- For category/payment icons:
  - Apply tint via `ColorFilter.mode(color, BlendMode.srcIn)` with `SvgPicture.asset`.
  - Preserve existing container size/padding to avoid layout regressions.
- Avoid introducing RenderFlex overflows:
  - Use `Expanded/Flexible` where text can grow.
  - Keep long labels ellipsized where needed.
- Do not alter typography/theme system unless requested (`GoogleFonts`, `AppColors`, existing tokens).

## 6) Database Rules
- DB migrations must be:
  - Backward-compatible
  - Idempotent
  - Wrapped safely (`try/catch`) where appropriate
- Never delete user data as part of migration unless explicitly required and approved.
- Any data repair on startup (UUID, asset paths, sync defaults) must be safe to run multiple times.

## 7) Dependency Rules
- Keep `flutter_svg` present in dependencies.
- Do not upgrade broad dependency ranges as part of unrelated fixes.
- Run `flutter pub get` only when dependency or asset changes require it.

## 8) Coding Rules
- Use null-safe, defensive code paths for DB-backed values.
- Prefer explicit naming and small helper methods over duplicated inline logic.
- Keep files/lints consistent with project style (`flutter_lints` defaults unless requested otherwise).
- Do not add dead code or placeholder TODOs.

## 9) Verification Rules (Before Completion)
- Must run:
  - `flutter pub get` (when needed)
  - `flutter analyze`
- Must verify:
  - No unresolved `assets/images/*.png` runtime references
  - No crashes due to missing assets
  - No unintended UI layout break in updated screens

## 10) Change Safety Rules
- Never use destructive git/file commands to discard unknown user work.
- Do not delete old assets until replacements are confirmed wired and reference scan is clean.
- For hotfixes, prioritize targeted patches over broad code churn.

## 11) Scope Rules
- If user asks for “full migration,” complete all steps end-to-end:
  - Discover
  - Replace assets
  - Update code
  - Verify
  - Clean up old references
- If user reports a production-blocking error, stop new feature work and fix root cause first.

## 12) Recommended Quick Checks
- Find old raster references:
  - `rg -n "assets/images/.*\\.png" lib`
- Find old image widget usage in category paths:
  - `rg -n "Image\\.asset\\(.*assetPath|assetPath" lib`
- Validate build health:
  - `flutter analyze`

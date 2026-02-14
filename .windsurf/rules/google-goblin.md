---
trigger: always_on
---

# GoobleGoblin Project Rules (Flutter)

## Project snapshot
- **Framework**: Flutter (Material)
- **State mgmt**: Riverpod (`flutter_riverpod`)
- **App entry**: `lib/main.dart`
  - Initializes `NotificationService`
  - Initializes `DatabaseHelper`
  - Wraps app with `ProviderScope`
  - Uses `_AppRouter` to route based on onboarding status (`isOnboardingNeededProvider`)
- **Navigation**:
  - Root: `MainScreen` with bottom nav (`navigationIndexProvider`)
- **Data layer**: repositories under `lib/data/repositories/*`
- **Local persistence**: `DatabaseHelper` under `lib/core/DB/db_helper.dart`
- **Theme**: `lib/core/theme/app_theme.dart` (use `AppTheme.darkTheme`, `AppColors`)
- **Auth**: biometric auth screen at `lib/features/auth/auth_gaurd.dart` (uses `local_auth` + `shared_preferences`)

## Golden rules
- Keep changes **minimal and consistent with existing patterns**.
- Prefer **Riverpod providers + StateNotifier** patterns already used in `lib/providers/*`.
- Do not introduce a new architecture (no Bloc/GetX/etc.) unless explicitly requested.

## Folder conventions
- `lib/features/<feature>/...` for UI/screens/widgets and feature-specific logic.
- `lib/providers/*_provider.dart` for app-wide providers/state notifiers.
- `lib/core/*` for cross-cutting concerns (theme, DB, utils, models).
- `lib/data/repositories/*` for data access abstractions + implementations.

## Riverpod rules
- For feature state:
  - Use `StateNotifier` + immutable `State` class with `copyWith()`.
  - Track:
    - `isLoading`
    - `errorMessage` (string)
    - primary data list/value
- For dependencies:
  - Expose repository via `Provider<Repo>` (see `cardRepositoryProvider`, `paymentRepositoryProvider`).
  - Expose notifier via `StateNotifierProvider<Notifier, State>`.
- When doing async loads:
  - Set loading true, clear error.
  - Use repository result folding pattern as already present.
- Don’t create duplicate providers:
  - Check `lib/providers/providers.dart` exports before adding new files.

## UI rules
- Use existing theme tokens:
  - `AppTheme.darkTheme`
  - `AppColors.*`
- Prefer `ConsumerWidget` / `Consumer` for reading providers.
- Keep screens in `features/<feature>/screens` (or existing naming in that feature).
- Avoid introducing new navigation frameworks; follow existing `Navigator.push(...)` style unless asked.

## Routing / startup rules
- Onboarding gating is centralized in `main.dart` via `_AppRouter`.
- If adding a new first-run gate:
  - Hook it into `_AppRouter` (or extend onboarding logic)
  - Keep fallback behavior safe (don’t brick the app on error)

## Persistence rules
- Use `DatabaseHelper.instance` for DB operations.
- Avoid calling DB init in random widgets; DB is initialized in `main()` already.
- Keep DB access behind repositories where feasible.

## Auth rules (biometrics)
- `AuthScreen` uses `local_auth` and stores `isAuthenticated` in `SharedPreferences`.
- If modifying auth flow:
  - Preserve `LocalAuthException` handling paths.
  - Don’t hardcode secrets.
  - Don’t block the UI thread; use `async/await`.

## Logging / toasts
- Prefer existing toast system (e.g., `AppToasts.showSuccessToast(context)` and `toastification` wrapper).
- Avoid `print()` in production logic; if you must log, keep it minimal and removable.

## Implementation checklist (when adding features)
- Add/extend:
  - `core/models/*` for new entities
  - `data/repositories/*` for data access
  - `providers/*_provider.dart` for state
  - `features/<feature>/screens/*` for UI
- Update:
  - `lib/providers/providers.dart` exports if adding a provider file used broadly
  - `MainScreen` tabs only if it belongs in bottom navigation

## Code style constraints
- Keep imports clean and sorted.
- Keep classes immutable where practical.
- Don’t rename public APIs/files without updating all references.
- Match existing naming:
  - `SomethingProvider`, `SomethingNotifier`, `SomethingState`
  - `...Screen` for screens

## What to ask before big changes
- Should this be global (`lib/providers`) or feature-scoped (`lib/features/.../providers`)?
- Should the user-facing flow go through onboarding gate (`_AppRouter`) or main navigation (`MainScreen`)?
markdown
// filepath: /Users/vtm/Documents/treespora/README.md
# Treespora
Plant goals. Harvest success.

## Structura proiectului (mobil)

```
lib/
└─ app/
   ├─ core/
   │  ├─ config/
   │  │  └─ app_config.dart
   │  ├─ navigation/
   │  │  └─ slide_up_full_screen_route.dart
   │  ├─ theme/
   │  │  ├─ theme.dart
   │  │  └─ animated_stars_background.dart
   │  └─ routes.dart              # AppRoutes + onboarding animations
   ├─ root/
   │  ├─ startup_screen.dart
   │  └─ welcome_screen.dart
   └─ features/
      ├─ auth/
      │  ├─ data/
      │  │  └─ auth_repository.dart
      │  └─ presentation/
      │     ├─ screens/
      │     └─ widgets/
      │        ├─ login_form.dart
      │        └─ signup_form.dart
      ├─ forest/
      │  └─ presentation/
      │     └─ screens/
      │        └─ forest_tab.dart
      ├─ goals/
      │  ├─ data/
      │  │  └─ goal_repository.dart
      │  ├─ domain/
      │  │  ├─ goal_composer.dart
      │  │  └─ goal_summary.dart
      │  └─ state/
      │     └─ active_goal_controller.dart
      ├─ home/
      │  ├─ root/
      │  │  └─ main_tab_shell.dart
      │  └─ presentation/
      │     ├─ screens/
      │     │  ├─ home_screen.dart
      │     │  └─ journey_goal_tab.dart
      │     └─ widgets/
      │        ├─ home_bottom_nav_bar.dart
      │        ├─ home_calendar_strip.dart
      │        └─ home_streak_header.dart
      ├─ onboarding/
      │  ├─ data/
      │  │  └─ onboarding_storage.dart
      │  ├─ state/
      │  │  └─ onboarding_state.dart
      │  └─ presentation/
      │     ├─ screens/
      │     │  ├─ age_question_screen.dart
      │     │  ├─ journey_stage_screen.dart
      │     │  ├─ onboarding_screen.dart
      │     │  ├─ source_screen.dart
      │     │  └─ time_commitment_screen.dart
      │     └─ widgets/
      │        ├─ animated_button.dart
      │        └─ rounded_progress_bar.dart
      └─ profile/
         └─ presentation/
            └─ screens/
               ├─ profile_screen.dart
               └─ profile_tab.dart

assets/
├─ Treespora_logo_transparent.png
├─ Logo.png
├─ apple.png
├─ appleB.png
├─ facebook.png
└─ google.png
```

## Structura proiectului (backend - WIP)

```
backend/
└─ app/
   ├─ api/         # Endpoints (ex: auth, profile, onboarding)
   ├─ core/        # Config, DI, logging, middlewares
   ├─ db/          # Conexiune DB, migrații, repo-uri
   ├─ queue/       # Setup cozi/background jobs
   ├─ schemas/     # DTO/validări (ex: Pydantic)
   └─ services/    # Logică domeniu, use cases
└─ workers/
   └─ tasks/       # Task-uri async (cron, email, procesări)
```

## Config / Lint

- `pubspec.yaml`: Dart SDK `^3.8.1`, dep: `shared_preferences`, `cupertino_icons`.
- `analysis_options.yaml`: include `flutter_lints` (v5).

## Supabase Auth (dev)

1. Set the runtime keys when running Flutter:
   ```bash
   flutter run --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-anon-key
   ```
2. Keys never live in source control. They are only read via `AppConfig` (see `lib/app/core/config/app_config.dart`).
3. The login bottom sheet (Welcome screen) and the sign-up sheet (Home screen) both talk to Supabase through `AuthRepository` (`lib/app/features/auth/data/auth_repository.dart`).

## Rulare rapidă (Flutter)

```bash
flutter pub get
flutter analyze
flutter run --dart-define=APP_NAME=Treespora
./run_dev.sh
```

Pentru web:
```bash
flutter run -d chrome
```

## Routing

- Centralizat în `lib/app/core/routes.dart`.
- Onboarding: `PageRouteBuilder` + `CupertinoPageTransition` pentru slide fluid.
- Pentru ecrane noi: adaugă constantă, import, și înscrie în `_routes` (sau `_onboardingRoutes`).

## Onboarding (flow actual)

1) Welcome → 2) Age → 3) Journey stage → 4) Time commitment → 5) Source.

Extensibil: validare input, salvare locală (SharedPreferences), trimitere către backend.

## Auth (UI)

`WelcomeScreen` afișează bottom sheet cu `LoginForm`.
Integrarea reală (Supabase OAuth/Email) urmează.

## Convenții

- Folosește `const` unde poți.
- Preferă barrel files pentru importuri curate când cresc modulele.
- Denumire ecrane: `SomethingScreen`.
- Ține componentele generice separat de cele specifice feature-ului (`widgets/` vs `features/...`).

## TODO (scurt, pragmatic)

- Conectare auth reală (Supabase: session, tokens, Google/Apple).
- Persistare răspunsuri onboarding (local + remote) + API DTO.
- State management (Riverpod/Bloc) pentru onboarding + auth.
- Teste widget + golden pentru componentele animate.
- L10n (intl) – pregătit pentru multilingv.
- CI simplu: `flutter analyze`, `flutter test`.
- Build flavors (dev/staging/prod) + `--dart-define` pentru baseUrl.

## Note

- Nu hardcoda secrete în app. Folosește `--dart-define`/config la build.
- API: toate call-urile printr-un client mic Dart cu `baseUrl` unic.
- Asset-urile sunt listate în `pubspec.yaml` (inclusiv logo-urile sociale).

---

Happy building 🌱
---

Dacă ai nevoie de un script de curățare importuri sau generare barrel files, cere explicit.

Happy building 🌱

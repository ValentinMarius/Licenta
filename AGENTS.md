# MODUS OPERANDI
- think hard, like a Senior Developer would .
- your task is to help me to build my AI Startup Treespora .
- always prioritize writing clean, simple and modular.
- do exactly what the user asks for, nothing more, nothing less.
- Check that you've implemented every requirement fully & completely .

- avoid feature creep at all cost. Avoid over-engineering and overthinking.
- Use simple & easy-to-understand language. Write in short sentences.
- Prioritize simplicity and minimalism in your solutions.

# ABOUT TREESPORA
Treespora is an AI-powered mobile app for personal development and productivity that transforms the way users achieve their goals.

The app provides dynamic plans that automatically update based on the user’s daily progress, reported through a daily check-in. Each check-in consists of AI-generated daily tasks designed to help the user steadily move toward their objective.

If a user submits a negative check-in (showing less progress than expected), the AI recalibrates the plan and adjusts upcoming tasks so that the goal can still be reached on time or as close to the target date as possible. Conversely, if the user makes faster-than-expected progress, the app adapts the plan to maintain a balanced and sustainable growth pace.


# TECH STACK
- we use FastAPI and Python for the Backend, hosted on Render.com
- Frontend: Flutter (Dart) – Cross-platform for Android & iOS
- PostgreSQL for the Database, hosted on Supabase
- Redis + Dramatiq for the Background Jobs, hosted on Render.com
- OpenRouter for the AI models (DeepSeek)
- Google Auth for auth , integrated with Supabase
- 


# CURRENT FILE STRUCTURE

```
lib/
├─ app/
│  ├─ core/
│  │  ├─ config/
│  │  │  └─ app_config.dart
│  │  ├─ navigation/
│  │  │  └─ slide_up_full_screen_route.dart
│  │  ├─ pages/
│  │  │  ├─ onboarding/
│  │  │  │  └─ widgets/
│  │  │  │     └─ animated_button.dart
│  │  │  └─ welcome_screen.dart
│  │  ├─ theme/
│  │  │  ├─ animated_stars_background.dart
│  │  │  └─ theme.dart
│  │  └─ routes.dart
│  ├─ root/
│  │  ├─ startup_screen.dart
│  │  └─ welcome_screen.dart
│  ├─ features/
│  │  ├─ auth/
│  │  │  ├─ data/
│  │  │  │  └─ auth_repository.dart
│  │  │  ├─ presentation/
│  │  │  │  ├─ screens/
│  │  │  │  └─ widgets/
│  │  │  │     ├─ login_form.dart
│  │  │  │     └─ signup_form.dart
│  │  │  ├─ screens/
│  │  │  └─ widgets/
│  │  │     ├─ login_form.dart
│  │  │     └─ signup_form.dart
│  │  ├─ forest/
│  │  │  └─ presentation/
│  │  │     └─ screens/
│  │  │        └─ forest_tab.dart
│  │  ├─ goals/
│  │  │  ├─ data/
│  │  │  │  ├─ goal_repository.dart
│  │  │  │  └─ plan_repository.dart
│  │  │  ├─ domain/
│  │  │  │  ├─ goal_composer.dart
│  │  │  │  ├─ goal_summary.dart
│  │  │  │  └─ plan_summary.dart
│  │  │  └─ state/
│  │  │     └─ active_goal_controller.dart
│  │  ├─ home/
│  │  │  ├─ root/
│  │  │  │  └─ main_tab_shell.dart
│  │  │  └─ presentation/
│  │  │     ├─ screens/
│  │  │     │  ├─ home_screen.dart
│  │  │     │  └─ journey_goal_tab.dart
│  │  │     └─ widgets/
│  │  │        ├─ home_bottom_nav_bar.dart
│  │  │        ├─ home_calendar_strip.dart
│  │  │        ├─ home_streak_header.dart
│  │  │        ├─ home_week_header.dart
│  │  │        └─ plan_summary_card.dart
│  │  ├─ onboarding/
│  │  │  ├─ data/
│  │  │  │  └─ onboarding_storage.dart
│  │  │  ├─ state/
│  │  │  │  └─ onboarding_state.dart
│  │  │  └─ presentation/
│  │  │     ├─ screens/
│  │  │     │  ├─ age_question_screen.dart
│  │  │     │  ├─ journey_stage_screen.dart
│  │  │     │  ├─ onboarding_screen.dart
│  │  │     │  ├─ source_screen.dart
│  │  │     │  └─ time_commitment_screen.dart
│  │  │     └─ widgets/
│  │  │        ├─ animated_button.dart
│  │  │        └─ rounded_progress_bar.dart
│  │  └─ profile/
│  │     ├─ data/
│  │     │  └─ profile_repository.dart
│  │     └─ presentation/
│  │        └─ screens/
│  │           ├─ profile_screen.dart
│  │           └─ profile_tab.dart
│  ├─ data/
│  └─ widgets/
├─ backend/
│  ├─ app/
│  │  ├─ api/
│  │  │  └─ plans.py
│  │  ├─ core/
│  │  │  └─ settings.py
│  │  ├─ db/
│  │  │  └─ session.py
│  │  ├─ main.py
│  │  ├─ queue/
│  │  ├─ schemas/
│  │  │  └─ plan_summary.py
│  │  └─ services/
│  │     ├─ llm_client.py
│  │     └─ plan_summary_service.py
│  └─ workers/
│     └─ tasks/
└─ main.dart

assets/
├─ Logo.png
├─ Treespora_logo_transparent.png
├─ apple.png
├─ appleB.png
├─ facebook.png
└─ google.png



# DEPLOYED ENVIRONMENTS
- Production: treespora, branch 'main'
- Staging: staging.treespora, branch 'staging'
- Development: dev.treespora, branch 'dev'
- the development process is: build something on localhost, do a PR into 'dev', test it in 'dev' for 1-2 days, merge into 'staging', test it in 'staging' for 1-2 days, merge into 'production'
- localhost uses the 'dev' database

# SCALABILITY
- Architecture ready for 10k+ daily active users.
- requests cached loaclly to reduce cost and latency
- Modular backend ready for multi-model AI

# DATABASE
- Staging uses the same DB as Production.
- Dev has a separate DB on Supabase, but with identical schema.
- our DB schema is documented in `/docs/supabase/supabase_setup.md`

# API
- mobile calls the backend over HTTPS.
- use a small Dart API client with a single baseUrl.
- never hardcode secrets in the app.
- example (Dart):

✅ await api.post('v1/goals', body: {...});

✅ await api.get('v1/goals/{id}');

- responses are JSON. validate on both sides (Pydantic in FastAPI, models in Dart).
- use auth tokens (Supabase or our JWT) on every request.


# COMMENTS
- every file should have clear Header Comments at the top, explaining where the file is, and what it does
- all comments should be clear, simple and easy-to-understand
- when writing code, make sure to add comments to the most complex / non-obvious parts of the code
- it is better to add more comments than less

# UI DESIGN PRINCIPLES
- the UI of Treespora needs to be simple, clean, and minimalistic
- we aim to achive great UI/UX, just like Apple or ChatGPT does
- the main colors are black & white
- Main font: Inter for every text style, bold weight on headings and buttons
- Main color: #111111 in light mode, #F5F5F5 in dark mode for strong primary elements
- Accent color: #2F7A5B (light) and #9DD7C0 (dark) for highlights
- Background color: #F4F6F8 (light) and #050608 (dark) for calm surfaces
- Text color: #111111 in light, #F2F2F2 in dark, taken from onBackground/onSurface tokens
- Button color: uses the primary color (#111111 light / #F5F5F5 dark) via ElevatedButtonTheme
- Button text color: onPrimary (#F5F5F5 light / #111111 dark) for maximum contrast
- Button hover color: primary shade with a subtle Material 3 hover overlay (≈8%) to keep the same hue while lightening it
- Button active color: primary shade with the pressed overlay (≈12%) for tactile feedback

# HEADER COMMENTS
- EVERY file HAS TO start with 4 lines of comments!
    1. exact file location in codebase
    2. clear description of what this file does
    3. clear description of WHY this file exists
    4. RELEVANT FILES:comma-separated list of 2-4 most relevant files
- NEVER delete these "header comments" from the files you're editing.

# SIMPLICITY
- Always prioritize writing clean, simple, and modular code.
- do not add unnecessary complications. SIMPLE = GOOD, COMPLEX = BAD.
- Implement precisely what the user asks for, without additional features or complexity.
- the fewer lines of code, the better.

# APPUs
- this is the main metric we track at Vectal
- APPU stands for "Active Paying Power Users"
- the beauty of this metric is that it has both CHURN and REVENUE GROWTH built in
- every decision we make should be to grow APPU


# HELP THE USER LEARN
- when coding, always explain what you are doing and why
- your job is to help the user learn & upskill himself, above all
- assume the user is an intelligent, tech savvy person -- but do not assume he knows the details
- explain everything clearly, simply, in easy-to-understand language. write in short sentences.

# RESTRICTIONS
- NEVER push to github unless the User explicitly tells you to
- DO NOT run 'npm run build' unless the User tells you to
- Do what has been asked; nothing more, nothing less


# FILE LENGTH
- we must keep all files under 300 LOC.
- right now, our codebase still has many files that break this
- files must be modular & single-purpose

# READING FILES
- always read the file in full, do not be lazy
- before making any code changes, start by finding & reading ALL of the relevant files
- never make changes without reading the entire file

# EGO
- do not make assumption. do not jump to conclusions.
- always consider multiple different approaches, just like a Senior Developer would

# CUSTOM CODE
- in general, I prefer to write custom code rather than adding external dependencies
- especially for the core functionality of the app (backend, infra, core business logic)
- it's fine to use some libraries / packages in the frontend, for complex things
- however as our codebase, userbase and company grows, we should seek to write everything custom

# WRITING STYLE
- each long sentence should be followed by two newline characters
- avoid long bullet lists
- write in natural, plain English. be conversational.
- avoid using overly complex language, and super long sentences

markdown
# Treespora

Treespora este o aplicație mobilă pentru organizarea obiectivelor personale și transformarea lor în planuri concrete de lucru. Aplicația folosește Flutter pentru interfața mobilă, FastAPI pentru backend și Supabase pentru autentificare și stocarea datelor.

## Repository

Repository GitHub:

[adauga_aici_link-ul_tau]

## Ce include proiectul

- aplicația Flutter din `lib/`
- backend-ul FastAPI din `backend/`
- platformele Flutter din `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`
- resursele grafice din `assets/`

## Cerințe

- Flutter SDK `^3.8.1`
- Python 3.9+ pentru backend
- cheile Supabase setate la rulare

## Instalare și rulare

### Varianta recomandată

```bash
./run_dev.sh
```

Aceasta este varianta care pornește tot ce trebuie: backend-ul FastAPI și aplicația Flutter, cu setările corecte.

### Rulare manuală

1. Instalează dependențele Flutter:

```bash
flutter pub get
```

2. Pornește backend-ul FastAPI din folderul `backend/`:

```bash
cd backend
python3 -m uvicorn app.main:app --reload --host 0.0.0.0
```

3. Într-un alt terminal, verifică proiectul Flutter:

```bash
flutter analyze
```

4. Pornește aplicația Flutter cu setările necesare:

```bash
flutter run \
	--dart-define=SUPABASE_URL=https://icogpatyypsirbrjryzb.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imljb2dwYXR5eXBzaXJicmpyeXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2MjQ0MTYsImV4cCI6MjA3ODIwMDQxNn0.uYTsB-EMzZFzX_JikDVF7X8HJleBFHf-wuZnyje5cyw \
	--dart-define=API_BASE_URL=http://localhost:8000
```



- fișierele generate automat, cache-urile și secretele nu sunt incluse în repository


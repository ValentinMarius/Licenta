# CAPITOLUL 1. INTRODUCERE
Capitolul prezinta aplicatia Treespora ca un produs de productivitate cu planuri generate automat si task-uri zilnice.
Sunt mentionate componentele reale: clientul Flutter, backend-ul FastAPI si baza de date Supabase.
Se fixeaza scopul: un flux simplu de la onboarding la obiective, plan si urmarirea progresului.

## 1.1 Contextul dezvoltarii aplicatiei
Subcapitolul explica presiunea actuala asupra gestionarii timpului si limitele solutiilor statice, unde utilizatorul trebuie sa fragmenteze manual obiectivele.
Treespora este prezentata ca raspuns printr-un flux automatizat ce transforma un obiectiv general intr-un plan de actiune, sustinut de client Flutter si backend FastAPI.
Contextul este completat de onboarding, unde se colecteaza parametri precum varsta, stadiul si timpul disponibil, pentru a genera un parcurs sustenabil.

## 1.2 Obiectivele proiectului si scopul aplicatiei
Subcapitolul defineste obiectivul principal: generarea unui plan si a task-urilor prin endpoint-urile /v1/goals/{id}/plan/summary si /v1/goals/{id}/tasks.
Scopul aplicatiei este sa ajute utilizatorul sa urmeze zilnic planul si sa vada progresul in Home.
Se mentioneaza rezultatele urmarite in produs, precum finalizarea obiectivelor si statisticile din Profile.

## 1.3 Definirea temei de proiectare
Subcapitolul stabileste tema centrata pe un flux automatizat, dar cu UI minimal si clar, deja folosit in Welcome si Home.
Este descrisa decizia de a separa logica in repository-uri si controllere, cum sunt AuthRepository si ActiveGoalController.
Sunt delimitate functiile livrate acum: autentificare, creare obiective, plan sumar si task-uri zilnice.

# CAPITOLUL 2. STUDIU BIBLIOGRAFIC
Capitolul leaga conceptele din literatura de comportamentele existente in aplicatie, precum task-uri zilnice si check-in.
Sunt comparate metodele clasice cu abordarea adaptiva pe care o ofera generarea automata.
Se pregateste justificarea pentru integrarea unui model precum DeepSeek.

## 2.1 Creionarea domeniului productivitatii si dezvoltarii personale
Subcapitolul descrie concepte ca obiective, obiceiuri si motivatie, legate de modul de utilizare al Treespora.
Se mentioneaza ca aplicatia traduce obiectivele in planuri cu zile numerotate si task-uri scurte.
Este explicata relevanta acestor concepte pentru UI-ul de progres.

## 2.2 Analiza solutiilor digitale existente si a metodelor de planificare
Subcapitolul compara aplicatii statice cu abordarea dinamica folosita aici, unde planul se genereaza server-side.
Se evidentiaza avantajul task-urilor limitate la 1-3 pe zi, conform schemei din plan_tasks.
Se motiveaza integrarea directa cu Supabase pentru stocare si sincronizare.

## 2.3 Evolutia Inteligentei Artificiale in asistarea utilizatorului
Subcapitolul explica trecerea catre modele de limbaj ca motor de generare a planului si a task-urilor.
Sunt mentionate constrangerile reale din prompt, cum sunt durata task-urilor intre 5 si 60 de minute.
Se arata de ce acest tip de AI ajuta la personalizare si la continuitate.

# CAPITOLUL 3. FUNDAMENTARE TEORETICA
Capitolul sintetizeaza tehnologiile folosite efectiv in cod: Flutter, FastAPI, Supabase si modele de limbaj.
Sunt explicate conceptele necesare pentru a intelege structura aplicatiei si fluxurile de date.
Include elementele de baza pentru plan summary si task planning.

## 3.1 Limbaje de programare si medii de dezvoltare
Subcapitolul explica alegerea Flutter pentru clientul mobil si FastAPI pentru backend.
Se mentioneaza organizarea in repository-uri si widget-uri ca structura de proiect.
Sunt prezentate avantajele de livrare rapida cu aceste tehnologii.

### 3.1.1 Limbajul Dart si framework-ul Flutter
Subcapitolul descrie UI-ul real: Welcome, Onboarding, Home, Journey, Forest si Profile.
Se explica modularizarea prin widget-uri precum TaskSection si HomeCalendarStrip.
Este mentionat controlul temei prin ThemeController.

### 3.1.2 Limbajul Python si framework-ul FastAPI
Subcapitolul prezinta backend-ul din backend/app, cu rute pentru summary si task plan.
Se mentioneaza dependintele pentru sesiunea async SQLAlchemy si setarile din .env.
Este explicat rolul serviciilor plan_summary_service si plan_tasks_service.

## 3.2 Tehnologii pentru gestiunea datelor si autentificare
Subcapitolul descrie persistenta in tabelele goals, ai_plans, tasks, day_check_ins si profiles.
Este explicata autentificarea prin Supabase si folosirea user_id in operatii.
Se leaga aceasta arhitectura de cerintele de securitate si consistenta.

### 3.2.1 Sistemul de gestiune a bazelor de date PostgreSQL
Subcapitolul arata cum datele sunt pastrate in Supabase, dar schema este PostgreSQL.
Se mentioneaza accesul prin SQLAlchemy in backend si prin Supabase client in Flutter.
Este justificata alegerea pentru date relationale si raportari.

### 3.2.2 Platforma Supabase ca solutie Backend-as-a-Service
Subcapitolul descrie folosirea Supabase pentru auth si pentru query-uri directe in Flutter.
Se mentioneaza AppConfig si folosirea --dart-define pentru chei.
Se arata cum Supabase permite sincronizarea rapida intre UI si date.

## 3.3 Modele de limbaj de mari dimensiuni (LLM)
Subcapitolul descrie rolul LLM in generarea planului sumar si a task-urilor.
Se mentioneaza contractele Pydantic pentru TaskPlanPrompt si TaskPlanResult.
Se explica de ce LLM este potrivit pentru continut personalizat.

### 3.3.1 Tehnologia GPT si evolutia modelelor Transformer
Subcapitolul ofera context despre modele de tip Transformer si output structurat JSON.
Este legat de metoda _extract_json_payload folosita in clientul LLM.
Se explica de ce acest tip de model suporta sumarizare si planificare.

### 3.3.2 Arhitectura modelului DeepSeek
Subcapitolul descrie integrarea concreta prin LlmClient si setarile DEEPSEEK_*.
Se mentioneaza regulile din TASK_PLANNER_SYSTEM_PROMPT pentru generarea task-urilor.
Se justifica alegerea prin controlul strict al structurii outputului.

# CAPITOLUL 4. SPECIFICATIILE APLICATIEI SI PROIECTARE
Capitolul traduce cerintele in arhitectura client-server folosita in Treespora.
Sunt detaliate rutele, modelele si fluxurile din backend si frontend.
Include proiectarea bazei de date si a fluxului real de generare.

## 4.1 Specificatiile functionale si nefunctionale
Subcapitolul descrie functionalitati precum login, onboarding, creare goal si generare task-uri.
Se mentioneaza cerinte de performanta, precum task-uri limitate si raspunsuri rapide.
Sunt incluse cerinte de securitate legate de cheile Supabase.

## 4.2 Arhitectura sistemului (Client-Server)
Subcapitolul prezinta clientul Flutter care consuma API-ul FastAPI prin HTTP.
Se mentioneaza endpoint-urile /v1/goals/{id}/plan/summary si /v1/goals/{id}/task_plan.
Este descrisa integrarea cu Supabase pentru date si sesiune.

## 4.3 Proiectarea bazei de date (Diagrama ER)
Subcapitolul descrie relatiile dintre goals, ai_plans, tasks, day_check_ins si profiles.
Se mentioneaza campuri cheie precum current_plan_id, target_date si completed_at.
Se leaga modelul de flow-ul de progres si de statisticile din Profile.

## 4.4 Proiectarea fluxului de generare a task-urilor
Subcapitolul explica pasii reali: citire goal, generare summary, persistare ai_plans si tasks.
Se mentioneaza validarea prin TaskPlanResult si normalizarea duratelor.
Se arata locul in care se actualizeaza target_date si plan_json.

### 4.4.1 Workflow-ul pentru Summary si Task Planning
Subcapitolul descrie cum PlanSummaryPrompt foloseste titlul, descrierea si contextul de profil.
Se explica apoi generarea task-urilor cu TaskPlanPrompt si salvarea in tasks.
Se mentioneaza call-ul de regenerare din TaskSection.

# CAPITOLUL 5. IMPLEMENTARE SI REZULTATE
Capitolul prezinta implementarea concreta in Flutter si FastAPI.
Se explica modul in care UI, starea si backend-ul colaboreaza in rulare.
Sunt mentionate rezultatele vizibile in progress si in statistici.

## 5.1 Implementarea serviciilor Backend
Subcapitolul descrie rutele FastAPI din plans.py si task_plans.py.
Se mentioneaza serviciile PlanSummaryService si PlanTasksService si rolul lor.
Se explica persistenta in ai_plans si tasks, plus logica de target_date.

## 5.2 Realizarea interfetei utilizatorului in Flutter
Subcapitolul descrie ecranele Welcome, Onboarding, Forest, Home, Journey si Profile.
Se mentioneaza componentele reutilizabile precum AnimatedButton si TaskTile.
Se explica navigatia prin AppRoutes si modal bottom sheets.

## 5.3 Vizualizarea progresului si managementul starii
Subcapitolul descrie TaskProgressStore si calculul progresului pe zile.
Se explica TreeGrowthProgress si segmentarea pe 5 etape in Home.
Se mentioneaza marcarea automata a obiectivelor completate in GoalRepository.

# CAPITOLUL 6. CONCLUZII
Capitolul rezuma faptul ca Treespora livreaza un flux complet de la goal la task-uri zilnice.
Sunt mentionate rezultatele: planuri generate, progres vizual si statistici in Profile.
Se noteaza directii clare de extindere, precum automatizarea check-in-urilor si optimizari de generare.

# BIBLIOGRAFIE
Sectiunea include surse despre Flutter, FastAPI, Supabase si modele LLM.
Sunt mentionate ghidurile pentru PostgreSQL si documentatia pentru DeepSeek prin OpenRouter.
Lista sustine deciziile tehnice prezente in implementare.

---
project: Bulk Tempo
version: 1
status: draft
created: 2026-10-07
updated: 2026-10-15
prd_version: 1
main_goal: speed
top_blocker: decisions
milestone_id: first-weekly-assessment
milestone_seq: 1
milestone_status: open
---

# Roadmap: Bulk Tempo

> Na podstawie `context/foundation/prd.md` (v1), dokumentów uzupełniających i sprawdzonego stanu aplikacji.
> Dokument aktualizowany w miejscu; zastąpioną wersję należy zachować w archiwum dokumentów fundamentowych.
> Kolejność poniżej wynika z zależności. Tabela „At a glance” jest indeksem.

## Milestone

**M-1: Pierwsza tygodniowa ocena masy i treningu** — Status: open

- **Intent:** Osoba korzystająca z prywatnego konta może zebrać pomiary masy i dane treningowe oraz zobaczyć tygodniową ocenę tempa na swoim urządzeniu. Ocena pokazuje kontekst co najmniej dwóch wcześniejszych tygodni i jasno sygnalizuje brak danych.
- **Source materials:** `context/foundation/prd.md` (v1); uzupełniająco `context/foundation/shape-notes.md`, `context/foundation/tech-stack.md`, `context/foundation/infrastructure.md`, `context/deployment/deploy-plan.md`.
- **Done when:** każdy element F-NN i S-NN poniżej ma status `done`, a główne kryterium sukcesu i trzy warunki ochronne z PRD można potwierdzić w aplikacji.
- **Scope anchors:** FR-001–FR-009, FR-012, US-01 oraz wymagania niefunkcjonalne i kontrola dostępu z PRD.

## Vision recap

Osoba budująca beztłuszczową masę dziś przenosi pomiary do arkusza i osobno sprawdza treningi. Bulk Tempo ma połączyć średnie i tempo zmian masy z postępem treningowym, tak by tygodniowa decyzja opierała się na jednym, czytelnym obrazie danych.

## North star

„North star” oznacza tutaj pierwszą kompletną funkcję, której działanie potwierdzi podstawową obietnicę produktu; jej zależności są wprowadzane tylko wtedy, gdy są potrzebne do tej oceny.

**S-07: Użytkownik może zobaczyć ocenę tempa w kontekście treningów i wcześniejszych tygodni** — to najmniejszy kompletny wynik odpowiadający głównemu kryterium sukcesu PRD.

## At a glance

| ID | Change ID | Outcome (user can …) | Prerequisites | PRD refs | Status |
| --- | --- | --- | --- | --- | --- |
| F-01 | private-data-verification | (foundation) uzgodniono i można sprawdzić izolację danych kont | — | FR-012, §Access Control, §Non-Functional Requirements | done |
| F-02 | workout-source-proof | (foundation) potwierdzono dostęp do przykładowych danych treningowych | — | FR-006 | blocked |
| S-01 | private-account-access | użytkownik może założyć konto, zalogować się i wylogować | — | FR-001 | done |
| S-02 | dated-weight-history | użytkownik może dodać dzisiejszy lub historyczny pomiar i odczytać go na innym urządzeniu | F-01, S-01 | FR-002, FR-005, FR-012 | done |
| S-03 | correct-weight-entry | użytkownik może poprawić lub usunąć własny błędny pomiar | S-02 | FR-003, FR-004 | done |
| S-04 | set-gain-target | użytkownik może ustawić i odczytać własny docelowy zakres przyrostu | F-01, S-01 | FR-007, FR-012 | in-progress |
| S-05 | import-workout-progress | użytkownik może pobrać własne treningi z ciężarami i powtórzeniami | F-01, F-02, S-01 | FR-006, FR-012 | in-progress |
| S-06 | weekly-progress-overview | użytkownik może zobaczyć tygodniowe podsumowanie masy i liczbę treningów | S-02, S-05 | FR-008, US-01 | done |
| S-07 | contextual-pace-assessment | użytkownik może zobaczyć ocenę tempa względem celu, wcześniejszych tygodni i treningów | S-04, S-06 | FR-008, FR-009, US-01, §Business Logic, §Non-Functional Requirements | blocked |

## Baseline

Stan aplikacji z 2026-10-07, sprawdzony w kodzie. Brak odpowiedzi korygującej przyjąłem jako potwierdzenie robocze.

- **Frontend:** partial — szkielet aplikacji wyświetla wyłącznie „Hello World!”; brak ekranów produktu (`bulk_tempo/lib/main.dart:15`).
- **Backend / API:** absent — brak obsługi żądań po stronie serwera; istnieje tylko konfiguracja adresu i klucza zewnętrznej usługi (`bulk_tempo/lib/core/constants/heavy_env.dart:1`).
- **Data:** partial — zależność od Realtime Database jest zadeklarowana, lecz nie ma operacji odczytu ani zapisu (`bulk_tempo/pubspec.yaml:14`, `bulk_tempo/lib/main.dart:7`). Dokument infrastruktury proponuje Cloud Firestore; wybór wymaga uzgodnienia.
- **Auth:** partial — zależność uwierzytelniania i inicjalizacja usługi istnieją, ale nie ma przepływu logowania ani ochrony danych (`bulk_tempo/pubspec.yaml:13`, `bulk_tempo/lib/main.dart:7`).
- **Deploy / infra:** partial — istnieje szkielet Androida i lokalna konfiguracja projektu usługi, ale nie ma gotowej ścieżki wydania ani automatyzacji (`bulk_tempo/android/app/build.gradle.kts:1`, `bulk_tempo/README.md:28`).
- **Observability:** absent — brak obsługi raportowania błędów i metryk w zależnościach oraz kodzie startowym (`bulk_tempo/pubspec.yaml:9`, `bulk_tempo/lib/main.dart:7`).

## Foundations

### F-01: Sprawdzalna izolacja prywatnych danych

- **Outcome:** (foundation) uzgodniono usługę danych kont i minimalny sposób sprawdzenia, że jedna osoba nie odczyta ani nie zmieni danych drugiej. Wybrano Firebase Realtime Database z regułami bezpieczeństwa per-user zdefiniowanymi w `database.rules.json` (`.read` / `.write` zastrzeżone dla `auth != null && auth.uid === $userId`).
- **Change ID:** private-data-verification
- **PRD refs:** FR-012, §Access Control, §Non-Functional Requirements
- **Unlocks:** S-02, S-04, S-05; sprawdzenie ochrony danych dwóch kont wymagane przez główne warunki ochronne PRD.
- **Prerequisites:** —
- **Parallel with:** F-02, S-01
- **Blockers:** —
- **Unknowns:**
  - Rozstrzygnięto na korzyść Firebase Realtime Database zgodnie z regułami `database.rules.json`.
- **Risk:** Wprowadzenie zapisów kont przed uzgodnieniem usługi i sposobu kontroli dostępu utrudni wykazanie prywatności danych.
- **Status:** done

### F-02: Dowód dostępu do źródła treningów

- **Outcome:** (foundation) potwierdzono na przykładowym treningu dopuszczalny dostęp do ciężarów i powtórzeń oraz sposób uprawnienia użytkownika.
- **Change ID:** workout-source-proof
- **PRD refs:** FR-006
- **Unlocks:** S-05; rozstrzygnięcie pytania, czy wymagany import jest możliwy dla kont pierwszych użytkowników.
- **Prerequisites:** —
- **Parallel with:** F-01, S-01
- **Blockers:** Dostęp do reprezentatywnego konta usługi treningowej i zgoda na sprawdzenie jego uprawnień.
- **Unknowns:**
  - Czy wybrana usługa udostępnia potrzebne dane pierwszym użytkownikom i jak zgodnie z jej zasadami uzyskuje się dostęp? — Owner: użytkownik. Block: yes.
- **Risk:** Bez próbki rzeczywistych danych można zaplanować import, którego użytkownicy nie będą mogli wykonać.
- **Status:** blocked

## Slices

### S-01: Dostęp do prywatnego konta

- **Outcome:** Użytkownik może założyć konto, zalogować się i wylogować z aplikacji.
- **Change ID:** private-account-access
- **PRD refs:** FR-001
- **Prerequisites:** —
- **Parallel with:** F-01, F-02
- **Blockers:** —
- **Unknowns:**
  - Czy samodzielne resetowanie zapomnianego hasła jest wymagane w pierwszej wersji? — Owner: użytkownik. Block: no.
- **Risk:** Należy sprawdzić rzeczywisty stan sesji przed podłączeniem prywatnych pomiarów; samo skonfigurowanie usługi nie daje użytkownikowi działającego konta.
- **Status:** done

### S-02: Historia pomiarów dostępna na koncie

- **Outcome:** Użytkownik może dodać dzisiejszy lub wcześniejszy pomiar masy i odczytać własne wpisy po zalogowaniu na innym urządzeniu.
- **Change ID:** dated-weight-history
- **PRD refs:** FR-002, FR-005, FR-012
- **Prerequisites:** F-01, S-01
- **Parallel with:** S-04, S-05
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Historyczna data musi należeć do pomiaru od początku, bo bez niej porównanie tygodni w S-07 będzie mylące.
- **Status:** done

### S-03: Korekta własnego pomiaru

- **Outcome:** Użytkownik może edytować lub usunąć błędny pomiar i zobaczyć poprawioną historię.
- **Change ID:** correct-weight-entry
- **PRD refs:** FR-003, FR-004
- **Prerequisites:** S-02
- **Parallel with:** S-04, S-05
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Zmiana historycznego wpisu musi odświeżyć późniejsze podsumowania, inaczej poprawka nie naprawi decyzji użytkownika.
- **Status:** done

### S-04: Własny zakres docelowy

- **Outcome:** Użytkownik może ustawić i później odczytać docelowy zakres tygodniowego przyrostu masy.
- **Change ID:** set-gain-target
- **PRD refs:** FR-007, FR-012
- **Prerequisites:** F-01, S-01
- **Parallel with:** S-02, S-03, S-05
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Zakres musi być jednoznaczny dla S-07, ale szczegóły obliczania statusu pozostają osobnym pytaniem.
- **Status:** in-progress

### S-05: Import postępu treningowego

- **Outcome:** Użytkownik może pobrać własne treningi z bieżącego i wcześniejszych tygodni wraz z ciężarami i liczbą powtórzeń.
- **Change ID:** import-workout-progress
- **PRD refs:** FR-006, FR-012
- **Prerequisites:** F-01, F-02, S-01
- **Parallel with:** S-02, S-03, S-04
- **Blockers:** F-02 (dostęp do reprezentatywnego konta i uprawnień)
- **Unknowns:**
  - Które dane i jaka miara najlepiej pokazują postęp treningowy w ocenie tygodnia? — Owner: użytkownik. Block: no.
- **Risk:** Zakres pobieranych treningów trzeba potwierdzić na rzeczywistych danych, zanim S-06 oprze na nich liczbę sesji.
- **Status:** in-progress

### S-06: Tygodniowy obraz postępów

- **Outcome:** Użytkownik może zobaczyć bieżące tempo zmiany masy, ostatnią średnią, łączny przyrost i liczbę treningów w tygodniu.
- **Change ID:** weekly-progress-overview
- **PRD refs:** FR-008, US-01
- **Prerequisites:** S-02, S-05
- **Parallel with:** S-03, S-04
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Ten widok powinien oznaczać niepełne lub nieaktualne dane, aby liczby nie wyglądały na pewne mimo przerwanego importu.
- **Status:** done

### S-07: Ocena tempa w kontekście masy i treningu

- **Outcome:** Użytkownik może zobaczyć, czy tempo jest prawidłowe, za szybkie, za wolne albo oznacza stagnację, z porównaniem co najmniej dwóch wcześniejszych tygodni i kontekstem treningowym.
- **Change ID:** contextual-pace-assessment
- **PRD refs:** FR-008, FR-009, US-01, §Business Logic, §Non-Functional Requirements
- **Prerequisites:** S-04, S-06
- **Parallel with:** S-03
- **Blockers:** —
- **Unknowns:**
  - Jaki wzór i granice rozstrzygają między czterema statusami tempa? — Owner: użytkownik. Block: yes.
  - Co aplikacja pokazuje, gdy brakuje pomiarów lub dwóch wcześniejszych tygodni? — Owner: użytkownik. Block: yes.
- **Risk:** Bez obu odpowiedzi wynik może wyglądać na precyzyjny, choć obliczenie lub porównanie nie ma wystarczających danych.
- **Status:** blocked

## Backlog Handoff

| Roadmap ID | Change ID | Suggested issue title | Ready for `/10x-plan` | Notes |
| --- | --- | --- | --- | --- |
| F-01 | private-data-verification | Uzgodnić i sprawdzić izolację danych kont | no | Rozwiązane (Firebase RTDB + database.rules.json). |
| F-02 | workout-source-proof | Potwierdzić dostęp do danych treningowych | no | Wymaga reprezentatywnego konta i zasad dostępu. |
| S-01 | private-account-access | Uruchomić prywatne konto w aplikacji | no | Zaimplementowane (done). |
| S-02 | dated-weight-history | Zapisywać i odczytywać pomiary z datą | no | Zaimplementowane (done). Zmergowane w PR #20. |
| S-03 | correct-weight-entry | Poprawiać błędne pomiary | yes | Gotowe do planowania (/10x-plan; S-02 gotowe). |
| S-04 | set-gain-target | Ustawiać docelowy przyrost masy | yes | Gotowe do planowania (/10x-plan; F-01 i S-01 gotowe). |
| S-05 | import-workout-progress | Importować postęp treningowy | no | Czeka na F-02; F-01 i S-01 są ukończone. |
| S-06 | weekly-progress-overview | Pokazać tygodniowy obraz postępów | no | Czeka na pomiary i treningi. |
| S-07 | contextual-pace-assessment | Ocenić tempo masy w kontekście treningu | no | Wymaga reguł oceny i brakujących danych. |

## Open Roadmap Questions

1. **Jaki dokładnie wzór i granice rozstrzygają między statusami „prawidłowe”, „za szybko”, „za wolno” i „stagnacja”?** — Owner: użytkownik. Block: S-07.
2. **Które dokładnie dane treningowe i jaka miara postępu najlepiej reprezentują kontekst treningowy?** — Owner: użytkownik. Block: nie; dotyczy S-05 i S-07.
3. **Jak aplikacja zachowuje się, gdy brakuje pomiarów albo nie ma jeszcze co najmniej dwóch wcześniejszych tygodni?** — Owner: użytkownik. Block: S-07.
4. **Czy użytkownik potrzebuje samodzielnego resetowania zapomnianego hasła w pierwszej wersji?** — Owner: użytkownik. Block: nie; dotyczy S-01.
5. **Która usługa danych obowiązuje w pierwszej wersji, skoro dokument infrastruktury proponuje inną niż zadeklarowana w aplikacji?** — Rozstrzygnięto: Firebase Realtime Database z regułami bezpieczeństwa per-user w `database.rules.json`. Status: rozwiązane (F-01 done).
6. **Czy wybrana usługa treningowa udostępnia wymagane dane każdemu pierwszemu użytkownikowi na dopuszczalnych warunkach?** — Owner: użytkownik. Block: F-02, S-05.

## Parked

- **Współdzielenie danych między kontami** — Why parked: PRD §Non-Goals wyklucza dostęp do danych innych osób.
- **Migracja wcześniejszych danych z urządzenia** — Why parked: PRD §Non-Goals stwierdza, że nie ma danych do przeniesienia.
- **Automatyczne wyznaczanie kalorii i planu diety** — Why parked: PRD §Non-Goals ogranicza produkt do oceny tempa masy.
- **Obowiązkowe wskazówki AI** — Why parked: PRD §Non-Goals i FR-011 czynią je opcjonalnym rozszerzeniem.
- **Przypomnienia o pomiarach** — Why parked: PRD §Non-Goals i FR-010 wyłączają je z pierwszego przepływu.
- **Wersje na inne platformy** — Why parked: PRD §Non-Goals ogranicza pierwszy zakres do aplikacji mobilnej.

## Milestone History

## Done

- **S-01: Dostęp do prywatnego konta** (`private-account-access`) — Obsługa rejestracji, logowania i wylogowania użytkownika.
- **S-02: Historia pomiarów dostępna na koncie** (`dated-weight-history`) — Zapisywanie i odczytywanie pomiarów z datą, walidacja i integracja z Firebase RTDB (PR #20).
- **S-03: Użytkownik może edytować lub usunąć błędny pomiar i zobaczyć poprawioną historię.** — Archived 2026-10-11 → `context/archive/2026-10-11-correct-weight-entry/`. Lesson: —.
- **S-06: Użytkownik może zobaczyć bieżące tempo zmiany masy, ostatnią średnią, łączny przyrost i liczbę treningów w tygodniu.** — Archived 2026-10-15 → `context/archive/2026-10-12-weekly-progress-overview/`. Lesson: —.

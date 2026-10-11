---
project: Bulk Tempo
context_type: greenfield
created: 2026-09-27
updated: 2026-10-02
checkpoint:
  current_phase: 8
  phases_completed: [1, 2, 3, 4, 5, 6, 7]
  gray_areas_resolved:
    - topic: pain_category
      decision: "Brak zintegrowanego obrazu postępów."
    - topic: product_insight
      decision: "Sama średnia masy ciała nie wystarcza — trzeba zestawić ją z tempem i treningiem."
    - topic: primary_persona_scope
      decision: "Każda osoba ocenia własne postępy na oddzielnym prywatnym koncie; pierwsza wersja dla kilku osób."
    - topic: access_control
      decision: "Oddzielne prywatne konta; rejestracja i logowanie przez e-mail oraz hasło."
    - topic: data_location
      decision: "Dane kont i pomiarów są przechowywane w chmurze; brak migracji istniejących danych lokalnych."
  frs_drafted: 12
  quality_check_status: accepted
timeline_budget:
  mvp_weeks: 5
  hard_deadline: 2026-12-06
  after_hours_only: true
product_type: mobile
target_scale:
  users: small
  qps: low
  data_volume: small
---

# Shape Notes

## Vision & Problem Statement

Osoba budująca beztłuszczową masę potrzebuje pod koniec tygodnia ocenić, czy masa ciała rośnie we właściwym tempie i jak ten trend ma się do postępu treningowego. Obecnie ręcznie przenosi pomiary wagi do Excela, liczy średnią, wpisuje wynik do Hevy, a czasami przygotowuje screeny treningów i pomiarów do analizy z AI.

Problemem jest brak zintegrowanego obrazu postępów. Sama średnia masy ciała nie wystarcza — decyzja wymaga zestawienia jej z tempem zmian i postępem treningowym.

## User & Persona

### Primary persona

Lifter budujący beztłuszczową masę, który pod koniec każdego tygodnia podejmuje decyzję o dalszym prowadzeniu masy na podstawie swoich pomiarów wagi i wyników treningowych. Produkt może służyć wielu takim osobom, z oddzielnymi prywatnymi kontami.

## Emerging Ideas

- Użytkownik zasugerował przypomnienia o pomiarach, ponieważ czasami o nich zapomina.
- Użytkownik zasugerował wskazówki dotyczące tego, czy jego kaloryczność jest odpowiednia.

## Access Control

Każda osoba zakłada własne konto i loguje się za pomocą adresu e-mail oraz hasła. Konta mają jednakowe uprawnienia, a każda osoba widzi i zmienia tylko własne dane. Niezalogowana osoba musi się zarejestrować lub zalogować, zanim uzyska dostęp do swoich pomiarów i dashboardu. Dane istniejące wcześniej lokalnie nie wymagają migracji.

## Success Criteria

### Primary

- Użytkownik otwiera aplikację i widzi dashboard z oceną, czy tempo przyrostu masy jest właściwe, wraz z porównaniem wyników treningowych bieżącego i co najmniej dwóch wcześniejszych tygodni.

### Secondary

- Użytkownik może korzystać z przypomnień o pomiarach lub wskazówek AI.

### Guardrails

- Średnie i trendy są obliczane poprawnie.
- Brakujące dane są jasno oznaczone zamiast ukrytego lub mylącego uzupełniania.
- Dane jednej osoby nie są widoczne ani modyfikowalne przez inną osobę.

## Timeline acknowledgment

Acknowledged on 2026-09-27: 4–5-week MVP requires sustained dedication; user accepted. Planning budget uses the upper bound of 5 weeks. On 2026-10-02, after adding private accounts and cloud data, the user kept the five-week after-hours estimate.

## Functional Requirements

- FR-001: Użytkownik może założyć prywatne konto oraz zalogować się i wylogować za pomocą adresu e-mail i hasła. Priority: must-have
  > Socrates: Counter-argument considered: jedno wspólne konto pozwoliłoby ograniczyć zakres pierwszej wersji. Resolution: pozostawiono oddzielne prywatne konta jako niezbędne w pierwszej wersji.
- FR-002: Użytkownik może dodać pomiar masy ciała. Priority: must-have
  > Socrates: Counter-argument considered: dodawanie pojedynczych pomiarów może być zbyt wolne przy większej historii. Resolution: pozostawiono dodawanie pojedynczych pomiarów w MVP.
- FR-003: Użytkownik może edytować pomiar masy ciała. Priority: must-have
  > Socrates: Counter-argument considered: w MVP może wystarczyć usunięcie błędnego wpisu i dodanie poprawnego. Resolution: edycja pozostaje w MVP zgodnie z wcześniejszym priorytetem; usunięcie i ponowne dodanie pozostaje możliwą alternatywą.
- FR-004: Użytkownik może usunąć pomiar masy ciała. Priority: must-have
  > Socrates: Counter-argument considered: usunięcie może zniekształcić wcześniejsze decyzje. Resolution: usuwanie pozostaje dostępne, przy świadomości tego ryzyka.
- FR-005: Użytkownik może dodać pomiar masy ciała z poprzedniego tygodnia lub wcześniejszej daty. Priority: must-have
  > Socrates: Counter-argument considered: bez historycznych pomiarów dashboard nie pokaże sensownego trendu. Resolution: historyczne pomiary pozostają wymaganiem MVP.
- FR-006: Użytkownik może pobrać z Hevy dane o treningach z bieżącego lub wcześniejszych tygodni, w tym ciężary i liczbę powtórzeń. Priority: must-have
  > Socrates: Counter-argument considered: sama liczba treningów nie wystarczy do oceny postępu siłowego. Resolution: wymaganie rozszerzono o pobieranie ciężarów i liczby powtórzeń.
- FR-007: Użytkownik może ustawić docelowy zakres tygodniowego przyrostu masy, np. 0,15–0,25 kg. Priority: must-have
  > Socrates: No counter-argument; it stands as written.
- FR-008: Użytkownik może zobaczyć na dashboardzie bieżące tempo, liczbę treningów w tygodniu, ostatnią średnią masy oraz łączny przyrost od początku okresu masowego. Priority: must-have
  > Socrates: No counter-argument; it stands as written.
- FR-009: Użytkownik może zobaczyć, czy przyrost w danym tygodniu mieści się w ustawionym zakresie względem średnich masy z co najmniej dwóch wcześniejszych tygodni. Priority: must-have
  > Socrates: Counter-argument considered: do oceny mogą być potrzebne co najmniej dwa wcześniejsze tygodnie. Resolution: wymaganie rozszerzono o porównanie z co najmniej dwoma wcześniejszymi tygodniami.
- FR-010: Użytkownik może korzystać z przypomnień o pomiarach. Priority: nice-to-have
  > Socrates: Counter-argument considered: przypomnienia są dodatkowym zakresem poza główną wartością MVP. Resolution: pozostają funkcją nice-to-have.
- FR-011: Użytkownik może korzystać ze wskazówek AI dotyczących przebiegu masy. Priority: nice-to-have
  > Socrates: Counter-argument considered: podstawowa reguła powinna działać bez AI. Resolution: AI pozostaje funkcją nice-to-have i nie jest wymagane do podstawowej decyzji.
- FR-012: Użytkownik może zapisywać swoje dane aplikacji na koncie oraz odczytywać je po zalogowaniu na innym urządzeniu. Priority: must-have
  > Socrates: Counter-argument considered: dostęp na drugim urządzeniu można byłoby odłożyć mimo przechowywania danych w chmurze. Resolution: pozostawiono dostęp na wielu urządzeniach; to samo konto musi działać na każdym z nich.

## User Stories

### US-01: Ocena tygodniowego tempa masy

- **Given** użytkownik ma konto z zapisanymi pomiarami masy oraz danymi treningowymi dla bieżącego i co najmniej dwóch wcześniejszych tygodni
- **When** loguje się i przechodzi do dashboardu
- **Then** widzi bieżące tempo zmiany masy, porównanie z ustawionym zakresem docelowym, liczbę treningów w bieżącym tygodniu, ostatnią średnią masy oraz łączny przyrost od początku okresu masowego

#### Acceptance Criteria

- Dashboard wskazuje, czy tygodniowy przyrost mieści się w ustawionym zakresie.
- Dashboard porównuje dane bieżącego tygodnia z co najmniej dwoma wcześniejszymi tygodniami.
- Brakujące dane są jasno oznaczone.
- Dashboard pokazuje wyłącznie dane zalogowanej osoby.

## Business Logic

Aplikacja ocenia, czy średni tygodniowy przyrost masy mieści się w ustawionym zakresie, porównując go z wcześniejszymi tygodniami i kontekstem postępu treningowego.

Reguła wykorzystuje codzienne pomiary masy wykonywane rano na czczo, wagę początkową oraz ustawiony docelowy zakres przyrostu. Uwzględnia także dane o ciężarach i liczbie powtórzeń z treningów.

Wynikiem jest ocena: „tempo prawidłowe”, „tempo za szybkie”, „tempo za wolne” albo „stagnacja”. Użytkownik widzi ją na dashboardzie.

## Non-Functional Requirements

- Dane aplikacji zapisane na koncie są dostępne wyłącznie tej osobie, także po zalogowaniu na innym urządzeniu.
- Status tempa jest prezentowany jednoznacznie jako „prawidłowe”, „za szybko”, „za wolno” albo „stagnacja”.

## Non-Goals

- Brak współdzielenia danych między kontami — każda osoba korzysta wyłącznie ze swoich danych.
- Brak migracji wcześniejszych danych lokalnych — nie ma istniejących danych, które trzeba przenieść.
- Brak automatycznego wyznaczania kalorii lub planu diety — aplikacja ocenia tempo masy, ale nie zastępuje planowania diety.
- Brak obowiązkowych wskazówek AI — podstawowa decyzja działa bez AI; AI może pojawić się później.
- Brak przypomnień o pomiarach w pierwszym przepływie — przypomnienia są opcjonalnym rozszerzeniem.
- Brak wersji na iOS lub inne platformy — zakres dotyczy Androida.

## Open Questions

1. **Jaki dokładnie wzór i granice rozstrzygają między statusami „prawidłowe”, „za szybko”, „za wolno” i „stagnacja”?** — Owner: użytkownik. Block: yes.
2. **Które dokładnie dane treningowe i jaka miara postępu najlepiej reprezentują kontekst treningowy?** — Owner: użytkownik. Block: no.
3. **Jak aplikacja zachowuje się, gdy brakuje pomiarów albo nie ma jeszcze co najmniej dwóch wcześniejszych tygodni?** — Owner: użytkownik. Block: yes.
4. **Czy użytkownik potrzebuje samodzielnego resetowania zapomnianego hasła w pierwszej wersji?** — Owner: użytkownik. Block: no.

## Forward: tech-stack

- Preferencja użytkownika: Firebase Authentication dla rejestracji i logowania oraz Firebase do przechowywania danych w chmurze. Konkretny sposób przechowywania danych zostanie ustalony podczas wyboru lub rewizji stosu technologicznego.

## Quality cross-check

Access Control, jednozdaniowa Business Logic, artefakt projektu, potwierdzony koszt pięciotygodniowego MVP i Non-Goals są obecne. Ponowna kontrola jakości zaakceptowana 2026-10-02.

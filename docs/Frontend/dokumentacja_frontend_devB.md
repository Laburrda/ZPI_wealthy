---

editor_options: 
  markdown: 
    wrap: 72
---

# Dokumentacja Zmian i Usprawnień Systemowych (Changelog & DevDocs)

Niniejszy dokument zawiera szczegółowy opis zmian architektonicznych, poprawek błędów kompilacji, integracji z backendem (FastAPI) oraz nowych modułów UI wprowadzonych w kodzie aplikacji.

------------------------------------------------------------------------

## 1. Moduł Autoryzacji i Ekranów Startowych

### Naprawa błędów kompilacji (`login_screen.dart`)

- **Problem:** Występował błąd krytyczny kompilatora Dart (`InvalidType(<invalid>)` / `Not a constant expression`) uniemożliwiający uruchomienie aplikacji z powodu błędnego traktowania widgetu docelowego jako stałej oraz braku jawnego importu klasy.
- **Rozwiązanie:** Dodano poprawny import pliku `register_screen.dart` oraz sformatowano nawigację wewnątrz BuildContext, usuwając modyfikator `const` przed konstruktorem klasy docelowej w parametrze `builder` nawigatora.

### Wdrożenie ekranu powitalnego (`LandingScreen`)

- **Nowość:** Stworzono nowy plik `lib/screens/landing_screen.dart` pełniący rolę punktu wejścia dla niezalogowanego użytkownika.
- **UI/UX:** Ekran zawiera centralnie umieszczony logotyp (ikona portfela), nagłówek powitalny oraz dwa spolaryzowane wizualnie przyciski: wypełniony `ElevatedButton` prowadzący do logowania oraz zarysowany `OutlinedButton` do rejestracji.
- **Konfiguracja `main.dart`:** Przepięto parametr `home` w głównym widżecie `MaterialApp` na klasę `LandingScreen()`, czyniąc go oficjalnym ekranem startowym aplikacji.

### Optymalizacja przepływu nawigacji (Stos ekranów)

- **Nawigacja wstecz:** Na ekranach logowania i rejestracji dodano przezroczysty komponent `AppBar`, w którym zaimplementowano funkcję `Navigator.popUntil(context, (route) => route.isFirst)`. Gwarantuje to bezpośredni powrót do `LandingScreen` bez tworzenia pętli historycznych w przypadku przechodzenia pomiędzy formularzami.
- **Czyszczenie stosu po zalogowaniu:** Zastąpiono standardowe `Navigator.pushReplacement` metodą `Navigator.pushAndRemoveUntil(..., (route) => false)`. Akcja ta całkowicie czyści historię nawigacji po autoryzacji, dzięki czemu domyślna strzałka powrotu na Dashboardzie zniknęła, a systemowy przycisk "wstecz" na telefonie bezpiecznie zamyka aplikację, zamiast cofać użytkownika do formularza logowania.

------------------------------------------------------------------------

## 2. Ekran Profilu Użytkownika (`AccountScreen`)

- **Nowość:** Stworzono dedykowany widok konta użytkownika (`lib/screens/account_screen.dart`).
- **Integracja API (`/auth/me`):** Wprowadzono asynchroniczny `userProfileProvider` typu `FutureProvider.autoDispose`, pobierający dane z endpointu profilowego bazy danych. W widoku zastosowano konstruktor `.when()`, optymalnie obsługujący stany `loading`, `error` oraz `data`.
- **Formatowanie danych:** Implementacja zawiera czyszczenie ciągów tekstowych daty utworzenia konta (`created_at`) poprzez odrzucenie informacji o strefie czasowej i godzinie (metoda `.split('T').first`), prezentując użytkownikowi czysty format `YYYY-MM-DD`.
- **Mechanizm Wylogowania:** Przycisk wylogowania wykonuje sekwencję: czyszczenie tokena uwierzytelniającego w pamięci podręcznej serwisu, zmianę stanu autoryzacji w Riverpod (`state = false`) oraz bezwarunkowe przekierowanie na `LandingScreen` z destrukcją dotychczasowego stosu nawigacyjnego.
- **Punkt Wejścia:** Przycisk profilu (`Icons.account_circle_outlined`) w formacie akcji paska górnego został pomyślnie zaimplementowany w `AppBar` Dashboardu.

------------------------------------------------------------------------

## 3. Integracja Dashboardu z API i Usunięcie Mocków

- **Zasilanie z sieci:** Zastąpiono lokalne, sztywne dane (mocki) wartościami pobieranymi asynchronicznie z endpointu `/dashboard/summary`.
- **Model `DashboardSummary`:** Stworzono dedykowany model danych parsujący strukturę JSON z backendu, uwzględniający m.in.: `total_assets_value`, `total_holdings_value`, `monthly_expense` oraz listę komunikatów systemowych.
- **Przeprojektowanie Płatności:** Całkowicie usunięto statyczną strukturę danych `UpcomingPaymentsNotifier`. W jej miejsce wdrożono `upcomingPaymentsProvider` (`FutureProvider`), pobierający dynamiczną listę nadchodzących obciążeń finansowych bezpośrednio z serwera i sortujący je chronologicznie po dacie zapadalności (`due_date`).
- **Asynchroniczny System Alertów:** Zmodyfikowano `dashboardAlertsProvider`. Łączy on teraz natywne komunikaty krytyczne przesyłane bezpośrednio z silnika FastAPI (mapowanie pól `severity` na stany `danger`/`warning`) z lokalną logiką ostrzeżeń o przekroczeniu 80% oraz 100% zdefiniowanego limitu budżetowego.

------------------------------------------------------------------------

## 4. Moduł Wydatków i Transakcji (`expenses_screen.dart`)

Wszystkie operacje w tym module zostały dostosowane do pełnej reaktywności i dynamicznej komunikacji z backendem.

### Zarządzanie Transakcjami (Dodawanie i Usuwanie)

- Formularz dodawania transakcji (`_AddExpenseSheet`) przesyła asynchronicznie do bazy danych spakowany obiekt JSON zgodny ze schematem `TransactionCreate` z FastAPI.
- Lista transakcji obsługuje natywne usuwanie rekordów za pomocą metody `deleteExpense(expense.id)` w notifierze, która wysyła żądanie `DELETE` do API i natychmiast unieważnia stan providera (`ref.invalidateSelf()`), dając efekt płynnego odświeżenia UI.

### Wybór i Modyfikacja Daty Transakcji

- Do struktur formularzy dodawania wydatków wprowadzono obsługę natywnego komponentu kalendarza systemowego `showDatePicker`.
- Wprowadzono ciemny motyw graficzny dla okna kalendarza spójny z paletą kolorów aplikacji (akcenty `Colors.tealAccent` dla kreacji). Wybrana data jest mapowana na format ISO (`YYYY-MM-DD`) przed wysyłką do bazy danych.

### Moduł Własnych Kategorii (`/categories/`)

- **Zarządzanie Kategoriami:** Dodano `_AddCategoryDialog` wywoływany dedykowanym przyciskiem `+` ulokowanym bezpośrednio obok kontrolera wyboru kategorii (Dropdown).
- **Payload API:** Okno pozwala użytkownikowi na zdefiniowanie nazwy kategorii, przypisanie reprezentacji graficznej w formie emotikony (Emoji) oraz wybór koloru z predefiniowanej palety HEX.
- **Reaktywność:** Po pomyślnym przetworzeniu żądania `POST` przez serwer, programowo wywołyvana jest metoda `ref.invalidate(categoriesProvider)`, co natychmiastowo aktualizuje listę dostępnych kategorii w otwartym arkuszu dodawania transakcji bez konieczności przeładowywania całego ekranu.

------------------------------------------------------------------------

## 5. Kompleksowy Moduł Emerytalny (`RetirementScreen`)

- **Problem architektury:** Dotychczasowy ekran kalkulatora obsługiwał wyłącznie symulacje inwestycji prywatnych, ignorując dedykowany endpoint dla filaru państwowego oraz pomijając istotne metryki zwracane przez API.
- **Rozwiązanie (Wykorzystanie Zakładek):** Przeprojektowano widok implementując `DefaultTabController` wraz z kontenerem `TabBarView`. Podzielono logikę na dwie niezależne karty symulacji.

### Karta 1: Emerytura Prywatna (Reguła 4%)

- **Komunikacja API:** Wysyła pakiet danych pod `/retirement/private-projection` (uwzględnia parametry transformowane do wartości dziesiętnych, np. `annual_return_rate: 0.06` zamiast `6.0`).
- **Wyświetlanie Wyników:** UI prezentuje teraz pełny zestaw danych z serwera: szacowaną docelową wartość portfela inwestycyjnego (`portfolio_at_retirement`) oraz kluczową z perspektywy rentiera wartość bezpiecznej, dożywotniej miesięcznej wypłaty (`monthly_sustainable_income`).
- **UX parametrów:** Zmodyfikowano suwak i powiązane etykiety tekstowe z mylącego "Zwrot" na jednoznaczne "Zysk z inwestycji (przed emeryturą)", aby odseparować pojęcie stopy wzrostu kapitału od stałej stopy wypłaty (4%).

### Karta 2: Emerytura Państwowa (Symulacja ZUS)

- **Nowość:** Zaimplementowano kompletną obsługę endpointu `POST /retirement/zus-projection`.
- **Parametry wejściowe:** Dodano suwaki powiązane ze stanem ekranu dla zmiennych wymaganych przez FastAPI: pensja brutto (`monthly_gross_salary`) oraz zgromadzony dotychczas kapitał składkowy (`accumulated_capital`).
- **Wyniki:** Widok prezentuje prognozowaną emeryturę nominalną w przyszłości oraz niezwykle istotną wartość siły nabywczej zwaloryzowaną do dzisiejszej wartości pieniądza (`monthly_pension_real_today_value`).

### Usprawnienia Interfejsu (UX/UI)

- W celu wyeliminowania podwójnych nagłówków systemowych i rezerwacji pustego miejsca przez framework, w komponencie `AppBar` ustawiono właściwość `toolbarHeight: 0`. Usunęło to nieestetyczną pustą przestrzeń, a pasek przełączania zakładek (`TabBar`) wskoczył na samą górę ekranu, podklejając się idealnie pod główny shell nawigacyjny aplikacji.

------------------------------------------------------------------------

## 6. Unifikacja Modułów Aktywów (Oszczędności i Inwestycje)

Dokonano pełnego audytu oraz refaktoryzacji kodu widoków zarządzania stanem posiadania w celu ujednolicenia doświadczenia użytkownika (User Experience).

### Ekran Inwestycji (`investments_screen.dart`)

- **Przeprojektowanie:** Całkowicie przebudowano strukturę pliku z prostego widoku listy na zaawansowany układ ListView wzorowany na ekranie oszczędności.

- **Wykres Kołowy (`fl_chart`):** Zintegrowano widżet `PieChart`. Implementacja mapuje dynamicznie posiadane aktywa na wycinki wykresu, wyliczając procentowy udział każdej pozycji w całości portfela.

- **Obsługa Walut:** Dodano wewnętrzny silnik przeliczania walut obcych (`USD`, `EUR`, `GBP`) na walutę bazową projektu (`PLN`) według ujednoliconych przeliczników, co pozwala na generowanie rzetelnej sumy skonsolidowanej wyświetlanej wewnątrz pierścienia wykresu.

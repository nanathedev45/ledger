# Ledger

A personal finance tracker for Android and iOS, built with Flutter. Track daily income and expenses, set category budgets, log savings contributions, and view reports with charts — plus a rule-based financial profile that classifies your spending habits and gives tailored advice.

Built as a learning project (personal use) and portfolio piece. Zero third-party UI packages — everything renders with the Flutter SDK.

---

## Features

### Core tracking
- **Balance card** with mask/reveal toggle (eye icon)
- **Add / Deduct** money with optional source or reason
- **Transaction history** across three tabs — All, Income, Expenditures
- **Currency formatting** — thousands separators (GH₵ 12,345.67)
- **Reset all** from a floating action button (with confirmation)

### Reports
- **Daily report** — today's totals + last-7-days net bar chart
- **Weekly report** — Monday-to-Sunday totals, with per-day bar chart
- **Monthly report** — full-month totals, with per-day bar chart
- **Scope filters** — each weekly/monthly report can show:
    - **Full period** (all days)
    - **Weekdays only** (Mon–Fri)
    - **Weekends only** (Sat–Sun)
- All reports recalculate on every transaction — no stale data

### Budget
- Per-category monthly limits (Food, Transport, Housing, Utilities, Entertainment, Shopping, Health, Education, Other)
- Progress bars with color thresholds — green <75%, amber 75–100%, red ≥100%
- Edit / delete existing budgets

### Savings
- Monthly savings target
- Log contributions (amount + optional note)
- Circular progress indicator + running total
- Contribution history with delete

### Financial profile ("ML")
- Rule-based classifier that analyzes the last 30 days of transactions
- Classifies you into one of 7 archetypes:
    - Steady Saver, Disciplined Builder, Cautious Spender, Balanced User,
      Impulse Spender, Paycheck-to-Paycheck, YOLO Spender
- Reports **4 feature signals** (savings rate, expense-to-income ratio, spending consistency, transaction frequency)
- Shows **confidence** based on how dominant the top archetype is
- Generates **tailored advice** based on archetype + context
- Works with any amount of data — falls back to "Insufficient Data" on empty history

### Navigation
- **App drawer** with 7 destinations: Home, Budget, Savings, Daily / Weekly / Monthly Report, Profile
- Drawer accessible from every screen, current screen highlighted

---

## What's working vs. planned

### Working on device
- All features listed above
- Reports, budget, savings, and profile persist **in memory** for the session

### Planned (deferred until environment allows)
- **Persistence** — transactions, budgets, savings, and PIN survive app restart. Requires shared_preferences, which needs CocoaPods on iOS (blocked by network/Big Sur) and Gradle on Android (deferred to an updated build machine).
- **PIN lock gate** — setup on first launch, unlock on subsequent opens. Needs crypto (pure Dart, works) + shared_preferences (blocked with persistence).
- **Category tagging on transactions** — the model field exists (categoryId), the picker in the add/deduct dialog is planned. Currently all transactions are Uncategorized, so budget rows read GH₵ 0.00 spent until this lands.
- **Bottom navigation** — deferred; drawer covers navigation for now.
- **Backdating** — date picker in the amount dialog so reports can show historical data.

---

## Tech stack

- **Flutter 3.7.2 / Dart 2.19.2** — a version pinned by the development machine (macOS Big Sur, Xcode 13.2)
- **No third-party packages** in dependencies: — only Flutter SDK + cupertino_icons
- Charts are **hand-rolled** (lib/widgets/simple_bar_chart.dart), not a package
- The "ML" engine is **deterministic rule-based scoring**, not a neural network — chosen for explainability, testability, and the ability to work with zero historical data

### Deliberate constraints

- **Dart 2.19** — no records, no patterns, no switch expressions. Every file conforms.
- **Zero native plugins** (until persistence) — sidesteps CocoaPods on iOS and Gradle-heavy first builds on Android.

---

## Project structure

lib/
├── main.dart                          Entry point; constructs state objects
├── app.dart                           MaterialApp root
├── models/
│   ├── transaction.dart               MoneyTransaction (immutable) + TransactionType enum
│   └── category.dart                  Preset categories (food, transport, salary, …)
├── state/
│   ├── ledger_state.dart              ChangeNotifier — transaction list, balance, add/clear
│   └── budget_state.dart              ChangeNotifier — per-category monthly limits
├── reports/
│   ├── reports.dart                   Pure functions: getDailySummary, getWeeklyReport,
│   │                                  getMonthlyReport, getCategoryBreakdown
│   │                                  + ReportScope enum (all / weekdays / weekends)
│   └── savings.dart                   SavingsGoal ChangeNotifier + contribution model
├── ml/
│   └── financial_profile.dart         Rule-based archetype classifier + advice generation
├── navigation/
│   └── screen_id.dart                 Screen identifier enum
├── utils/
│   ├── date_format.dart               formatDateTime helper (no intl dependency)
│   └── currency_format.dart           formatAmount — thousands separators
├── screens/
│   ├── home_screen.dart               Balance + add/deduct + tabs + reset FAB
│   ├── budget_screen.dart             Category budget editor
│   ├── savings_screen.dart            Monthly target + contributions
│   ├── daily_report_screen.dart       Today + last-7-days chart
│   ├── weekly_report_screen.dart      Weekly totals + scope chips + chart
│   ├── monthly_report_screen.dart     Monthly totals + scope chips + chart
│   └── profile_screen.dart            Archetype + signals + advice
└── widgets/
├── balance_card.dart              Masked/unmasked amount (Flexible + FittedBox)
├── ledger_drawer.dart             Shared navigation drawer
├── transaction_buttons.dart       Add (green) / Deduct (red)
├── transaction_tile.dart          One row — hand-built for width safety
└── simple_bar_chart.dart          Hand-rolled bar chart (no dependencies)

test/
├── reports/
│   └── reports_test.dart              Daily/weekly/monthly/breakdown unit tests
└── ml/
└── financial_profile_test.dart    Archetype classifier unit tests

### Architecture notes

- **state/** holds ChangeNotifier classes. UI rebuilds via AnimatedBuilder. Three state objects (LedgerState, BudgetState, SavingsGoal) live for the app's lifetime, constructed in main.dart and threaded through constructors to every screen and the drawer. No Provider, no InheritedWidget — deliberate zero-dependency choice.
- **reports/** contains **pure functions** (no Flutter imports). Testable in isolation with plain Dart. test/reports/reports_test.dart exercises them.
- **ml/** is likewise pure Dart — computeProfile(transactions, ...) returns a FinancialProfile. No I/O, no timers, no randomness.
- **widgets/** are presentation-only. No screen depends on another screen; all cross-screen navigation goes through Navigator.push from the drawer.

---

## Running

### Prerequisites
- Flutter SDK 3.7.2 or later (project pins environment: sdk: '>=2.19.2 <3.0.0')
- macOS with Xcode for iOS, or Android SDK for Android (or both)

### Setup

git clone https://github.com/nanathedev45/ledger.git
cd ledger
flutter pub get

### Run

flutter devices                              # list connected devices
flutter run -d <device-id>                   # hot reload enabled
flutter run -d chrome                        # web fallback

### Build

flutter build apk --release                  # Android APK
flutter build ipa --release                  # iOS IPA (requires signing setup)

### Test

flutter test                                 # run all tests
flutter test test/reports/reports_test.dart  # just reports
flutter test test/ml/financial_profile_test.dart

### Analyze

flutter analyze                              # static analysis (0 issues expected)

---

## Currency

Currently hardcoded as **Ghanaian Cedi (GH₵)** in lib/utils/currency_format.dart and in every display site. A CurrencyConfig refactor (symbol, decimal places, locale-aware separators) is planned but not blocking — all occurrences are string literals, easily grepped and replaced.

---

## Known limitations

- **No persistence.** Closing the app resets transactions, budgets, savings, and profile. (Planned; blocked on shared_preferences availability on the current development machine.)
- **No PIN lock.** (Planned; same blocker as persistence for storage.)
- **No transaction categories yet in the UI.** MoneyTransaction.categoryId exists; the add/deduct dialog doesn't yet offer a picker. All transactions are Uncategorized until the picker ships — meaning Budget rows read GH₵ 0.00 spent until then.
- **No backdating.** You can only log transactions at "now." Reports for past days therefore show flat bars until backdating is added.
- **Charts are minimal.** The bar chart shows bars only; labels are dropped below a certain bar width (e.g., the 30-day monthly chart). No line charts, no pie charts.

---

## Roadmap

Roadmap items, in suggested order:

1. **Category picker in add/deduct dialog** — makes budget rows show real spent values
2. **Persistence** — shared_preferences on an environment where it installs (fresh Android toolchain, or an updated Mac)
3. **PIN lock gate** — setup + unlock screens, hashed storage
4. **Backdating** — date picker in the amount dialog
5. **Category breakdown in reports** — getCategoryBreakdown already exists; wire it into the three report screens
6. **Bottom navigation bar** — promote 3–4 screens; drawer for the rest
7. **Currency config** — lib/utils/currency_config.dart with symbol, decimal places, locale
8. **Month axis labels** on the monthly bar chart
9. **Tests** — more archetype cases, edge cases around month boundaries

---

## License

Personal project. No license specified — treat as all rights reserved unless explicitly stated.

---

## Acknowledgments

Built with Flutter (https://flutter.dev). Charts hand-rolled. No design system used — Material 3 widgets from the SDK only.

The financial archetypes and advice text are inspired by common patterns in budget apps (YNAB, Copilot Money, Mint), interpreted through a rule-based classifier. The engine is deliberately **transparent** — every signal and every score is inspectable and editable in lib/ml/financial_profile.dart.
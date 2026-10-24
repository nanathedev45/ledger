// lib/models/category.dart
//
// Preset spending/income categories. Used by the add/deduct dialog,
// budget limits, category breakdowns in reports, and the financial
// profile engine.
//
// `id` is stored on transactions (stable across versions).
// `label` is displayed to users (can change freely).

class Category {
  final String id;
  final String label;
  final bool isExpense;
  final bool isIncome;

  const Category({
    required this.id,
    required this.label,
    required this.isExpense,
    required this.isIncome,
  });
}

class Categories {
  static const food = Category(
      id: 'food', label: 'Food', isExpense: true, isIncome: false);
  static const transport = Category(
      id: 'transport', label: 'Transport', isExpense: true, isIncome: false);
  static const housing = Category(
      id: 'housing', label: 'Housing', isExpense: true, isIncome: false);
  static const utilities = Category(
      id: 'utilities', label: 'Utilities', isExpense: true, isIncome: false);
  static const entertainment = Category(
      id: 'entertainment',
      label: 'Entertainment',
      isExpense: true,
      isIncome: false);
  static const shopping = Category(
      id: 'shopping', label: 'Shopping', isExpense: true, isIncome: false);
  static const health = Category(
      id: 'health', label: 'Health', isExpense: true, isIncome: false);
  static const education = Category(
      id: 'education',
      label: 'Education',
      isExpense: true,
      isIncome: false);
  static const otherExpense = Category(
      id: 'other_expense',
      label: 'Other',
      isExpense: true,
      isIncome: false);

  static const salary = Category(
      id: 'salary', label: 'Salary', isExpense: false, isIncome: true);
  static const gift = Category(
      id: 'gift', label: 'Gift', isExpense: false, isIncome: true);
  static const allowance = Category(
      id: 'allowance', label: 'Allowance', isExpense: false, isIncome: true);
  static const otherIncome = Category(
      id: 'other_income',
      label: 'Other',
      isExpense: false,
      isIncome: true);

  /// Preset categories for expense transactions.
  static const expensePresets = <Category>[
    food, transport, housing, utilities, entertainment, shopping,
    health, education, otherExpense,
  ];

  /// Preset categories for income transactions.
  static const incomePresets = <Category>[
    salary, gift, allowance, otherIncome,
  ];

  static List<Category> presetsFor({required bool isIncome}) =>
      isIncome ? incomePresets : expensePresets;

  /// Lookup by id. Returns null for unknown (e.g., user typed custom).
  static Category? byId(String? id) {
    if (id == null) return null;
    for (final c in [...expensePresets, ...incomePresets]) {
      if (c.id == id) return c;
    }
    return null;
  }

  static String labelOf(String? id) => byId(id)?.label ?? 'Uncategorized';
}
// lib/ml/financial_profile.dart
//
// Financial profile engine. Extracts features from a transaction history
// and classifies the user into one of several archetypes based on weighted
// scoring. Produces per-feature reasoning + tailored advice.
//
// Deterministic, explainable, works with any amount of data (including
// zero, which falls back to "Insufficient Data").

import '../models/transaction.dart';

/// The archetypes the engine can classify into.
enum FinancialArchetype {
  insufficientData,
  steadySaver,
  disciplinedBuilder,
  cautiousSpender,
  balancedUser,
  impulseSpender,
  paycheckToPaycheck,
  yoloSpender,
}

/// One feature's contribution to the final score.
class FeatureSignal {
  final String name;
  final double value;
  final String interpretation;

  const FeatureSignal({
    required this.name,
    required this.value,
    required this.interpretation,
  });
}

/// One piece of advice.
class Advice {
  final String headline;
  final String detail;
  final String severity; // 'positive' | 'neutral' | 'warning'

  const Advice({
    required this.headline,
    required this.detail,
    required this.severity,
  });
}

/// The computed profile.
class FinancialProfile {
  final FinancialArchetype archetype;
  final String archetypeLabel;
  final String summary;
  final List<FeatureSignal> signals;
  final List<Advice> advice;
  final double confidence;

  const FinancialProfile({
    required this.archetype,
    required this.archetypeLabel,
    required this.summary,
    required this.signals,
    required this.advice,
    required this.confidence,
  });
}

/// Internal helper — replaces the Dart 3 record tuple used earlier.
class _ArchetypeMeta {
  final String label;
  final String summary;
  const _ArchetypeMeta(this.label, this.summary);
}

/// Compute a profile from transactions over the last `windowDays` days.
FinancialProfile computeProfile(
    List<MoneyTransaction> transactions, {
      int windowDays = 30,
      double? monthlyBudget,
    }) {
  final now = DateTime.now();
  final start = now.subtract(Duration(days: windowDays));

  final inWindow = transactions
      .where((t) => t.dateTime.isAfter(start))
      .toList(growable: false);

  if (inWindow.isEmpty) {
    return const FinancialProfile(
      archetype: FinancialArchetype.insufficientData,
      archetypeLabel: 'Insufficient Data',
      summary: 'Log a few transactions to unlock your financial profile.',
      signals: [],
      advice: [
        Advice(
          headline: 'Start logging',
          detail:
          'The engine needs at least a few transactions (income and '
              'expense) in the last 30 days to give meaningful advice.',
          severity: 'neutral',
        ),
      ],
      confidence: 0.0,
    );
  }

  // ── Feature extraction ─────────────────────────────────────────────
  double totalIncome = 0;
  double totalExpense = 0;
  final expenseByDay = <int, double>{};

  for (final t in inWindow) {
    if (t.isIncome) {
      totalIncome += t.amount;
    } else {
      totalExpense += t.amount;
      final day = t.dateTime.day;
      expenseByDay[day] = (expenseByDay[day] ?? 0) + t.amount;
    }
  }

  final savingsRate =
  totalIncome > 0 ? (totalIncome - totalExpense) / totalIncome : 0.0;
  final expenseRatio = totalIncome > 0 ? totalExpense / totalIncome : 1.0;

  // Coefficient of variation of daily expenses.
  double variance = 0;
  if (expenseByDay.isNotEmpty) {
    final mean = totalExpense / expenseByDay.length;
    variance = expenseByDay.values
        .map((v) => (v - mean) * (v - mean))
        .fold(0.0, (a, b) => a + b) /
        expenseByDay.length;
  }
  final stdev = variance > 0 ? _sqrt(variance) : 0.0;
  final cv = totalExpense > 0 ? stdev / (totalExpense / 30.0) : 0.0;

  final perWeek = inWindow.length / (windowDays / 7.0);

  // ── Signals ────────────────────────────────────────────────────────
  final signals = <FeatureSignal>[
    FeatureSignal(
      name: 'Savings rate',
      value: savingsRate.clamp(0.0, 1.0),
      interpretation: savingsRate >= 0.3
          ? 'Strong — you save ${(savingsRate * 100).toStringAsFixed(0)}% of income.'
          : savingsRate >= 0.1
          ? 'Moderate — you save ${(savingsRate * 100).toStringAsFixed(0)}% of income.'
          : savingsRate >= 0
          ? 'Thin — you save only ${(savingsRate * 100).toStringAsFixed(0)}%.'
          : 'Negative — you spend more than you earn.',
    ),
    FeatureSignal(
      name: 'Expense-to-income',
      value: expenseRatio.clamp(0.0, 2.0) / 2.0,
      interpretation: expenseRatio <= 0.7
          ? 'Healthy ratio.'
          : expenseRatio <= 1.0
          ? 'Tight — you spend most of your income.'
          : 'Overspending — expenses exceed income.',
    ),
    FeatureSignal(
      name: 'Spending consistency',
      value: (1.0 - cv.clamp(0.0, 1.0)).clamp(0.0, 1.0),
      interpretation: cv < 0.5
          ? 'Steady day-to-day spending.'
          : 'Volatile — some days much higher than others.',
    ),
    FeatureSignal(
      name: 'Transaction frequency',
      value: (perWeek / 20.0).clamp(0.0, 1.0),
      interpretation: perWeek > 10
          ? 'Frequent transactions (${perWeek.toStringAsFixed(1)}/week).'
          : perWeek > 3
          ? 'Occasional transactions (${perWeek.toStringAsFixed(1)}/week).'
          : 'Rare transactions (${perWeek.toStringAsFixed(1)}/week).',
    ),
  ];

  // ── Archetype scoring ──────────────────────────────────────────────
  final scores = <FinancialArchetype, double>{
    FinancialArchetype.steadySaver: 0,
    FinancialArchetype.disciplinedBuilder: 0,
    FinancialArchetype.cautiousSpender: 0,
    FinancialArchetype.balancedUser: 0,
    FinancialArchetype.impulseSpender: 0,
    FinancialArchetype.paycheckToPaycheck: 0,
    FinancialArchetype.yoloSpender: 0,
  };

  if (savingsRate >= 0.4) {
    scores[FinancialArchetype.steadySaver] =
        scores[FinancialArchetype.steadySaver]! + 3;
    scores[FinancialArchetype.disciplinedBuilder] =
        scores[FinancialArchetype.disciplinedBuilder]! + 2;
  } else if (savingsRate >= 0.2) {
    scores[FinancialArchetype.steadySaver] =
        scores[FinancialArchetype.steadySaver]! + 2;
    scores[FinancialArchetype.balancedUser] =
        scores[FinancialArchetype.balancedUser]! + 1;
  } else if (savingsRate >= 0.05) {
    scores[FinancialArchetype.balancedUser] =
        scores[FinancialArchetype.balancedUser]! + 2;
    scores[FinancialArchetype.cautiousSpender] =
        scores[FinancialArchetype.cautiousSpender]! + 1;
  } else if (savingsRate >= 0) {
    scores[FinancialArchetype.paycheckToPaycheck] =
        scores[FinancialArchetype.paycheckToPaycheck]! + 2;
    scores[FinancialArchetype.cautiousSpender] =
        scores[FinancialArchetype.cautiousSpender]! + 1;
  } else {
    scores[FinancialArchetype.yoloSpender] =
        scores[FinancialArchetype.yoloSpender]! + 3;
    scores[FinancialArchetype.paycheckToPaycheck] =
        scores[FinancialArchetype.paycheckToPaycheck]! + 2;
  }

  if (cv < 0.5 && totalExpense > 0) {
    scores[FinancialArchetype.disciplinedBuilder] =
        scores[FinancialArchetype.disciplinedBuilder]! + 1.5;
    scores[FinancialArchetype.steadySaver] =
        scores[FinancialArchetype.steadySaver]! + 1;
  } else if (cv > 1.0) {
    scores[FinancialArchetype.impulseSpender] =
        scores[FinancialArchetype.impulseSpender]! + 2;
    scores[FinancialArchetype.yoloSpender] =
        scores[FinancialArchetype.yoloSpender]! + 1;
  }

  if (expenseRatio > 1.0) {
    scores[FinancialArchetype.yoloSpender] =
        scores[FinancialArchetype.yoloSpender]! + 1.5;
  } else if (expenseRatio < 0.6 && totalIncome > 0) {
    scores[FinancialArchetype.disciplinedBuilder] =
        scores[FinancialArchetype.disciplinedBuilder]! + 1;
  }

  var best = FinancialArchetype.balancedUser;
  var bestScore = -1.0;
  scores.forEach((arch, score) {
    if (score > bestScore) {
      bestScore = score;
      best = arch;
    }
  });

  final sortedScores = scores.values.toList()..sort((a, b) => b.compareTo(a));
  final margin =
  sortedScores.length > 1 ? (sortedScores[0] - sortedScores[1]) : 1.0;
  final confidence = (margin / 3.0).clamp(0.0, 1.0);

  final meta = _archetypeMeta(best);
  final advice = _generateAdvice(
    archetype: best,
    savingsRate: savingsRate,
    expenseRatio: expenseRatio,
    cv: cv,
    monthlyBudget: monthlyBudget,
  );

  return FinancialProfile(
    archetype: best,
    archetypeLabel: meta.label,
    summary: meta.summary,
    signals: signals,
    advice: advice,
    confidence: confidence,
  );
}

_ArchetypeMeta _archetypeMeta(FinancialArchetype arch) {
  switch (arch) {
    case FinancialArchetype.steadySaver:
      return const _ArchetypeMeta(
        'Steady Saver',
        'You consistently keep a healthy margin between income and spend.',
      );
    case FinancialArchetype.disciplinedBuilder:
      return const _ArchetypeMeta(
        'Disciplined Builder',
        'Your spending is predictable and you make room for savings.',
      );
    case FinancialArchetype.cautiousSpender:
      return const _ArchetypeMeta(
        'Cautious Spender',
        'You keep spending controlled but have room to save more.',
      );
    case FinancialArchetype.balancedUser:
      return const _ArchetypeMeta(
        'Balanced User',
        'You earn and spend in rough balance — neither thrifty nor reckless.',
      );
    case FinancialArchetype.impulseSpender:
      return const _ArchetypeMeta(
        'Impulse Spender',
        'Some days carry much higher spend than others — watch for spikes.',
      );
    case FinancialArchetype.paycheckToPaycheck:
      return const _ArchetypeMeta(
        'Paycheck-to-Paycheck',
        'Money goes out almost as fast as it comes in.',
      );
    case FinancialArchetype.yoloSpender:
      return const _ArchetypeMeta(
        'YOLO Spender',
        'Your expenses regularly exceed income. Time to rein in.',
      );
    case FinancialArchetype.insufficientData:
      return const _ArchetypeMeta(
        'Insufficient Data',
        'Log more transactions to see a profile.',
      );
  }
}

List<Advice> _generateAdvice({
  required FinancialArchetype archetype,
  required double savingsRate,
  required double expenseRatio,
  required double cv,
  double? monthlyBudget,
}) {
  final tips = <Advice>[];

  switch (archetype) {
    case FinancialArchetype.steadySaver:
      tips.add(const Advice(
        headline: 'Keep it up',
        detail: 'Your savings rate is strong. Consider setting an even '
            'higher savings target this month to stretch further.',
        severity: 'positive',
      ));
      break;
    case FinancialArchetype.disciplinedBuilder:
      tips.add(const Advice(
        headline: 'Solid foundation',
        detail: 'Predictable spending is a real asset. Consider allocating '
            'a portion to a savings goal.',
        severity: 'positive',
      ));
      break;
    case FinancialArchetype.cautiousSpender:
      tips.add(const Advice(
        headline: 'Small push',
        detail: 'You\'re comfortable but not saving much. Try moving 5% '
            'more of your income to savings next month.',
        severity: 'neutral',
      ));
      break;
    case FinancialArchetype.balancedUser:
      tips.add(const Advice(
        headline: 'Stay balanced',
        detail: 'You spend roughly what you earn. The biggest gains come '
            'from automating a small monthly savings transfer.',
        severity: 'neutral',
      ));
      break;
    case FinancialArchetype.impulseSpender:
      tips.add(const Advice(
        headline: 'Watch the spikes',
        detail: 'Some days see much higher spending. Try batching '
            'discretionary purchases or setting a per-day cap.',
        severity: 'warning',
      ));
      break;
    case FinancialArchetype.paycheckToPaycheck:
      tips.add(const Advice(
        headline: 'Build a buffer',
        detail: 'Aim to keep a small margin each month. Even GH₵50 '
            'retained is progress. Consider trimming one recurring expense.',
        severity: 'warning',
      ));
      break;
    case FinancialArchetype.yoloSpender:
      tips.add(const Advice(
        headline: 'Invert the trend',
        detail: 'Expenses exceed income. Identify your top 3 expense '
            'categories this month and try to reduce each by 20%.',
        severity: 'warning',
      ));
      break;
    case FinancialArchetype.insufficientData:
      break;
  }

  if (expenseRatio > 0.9 && expenseRatio <= 1.0) {
    tips.add(const Advice(
      headline: 'No margin left',
      detail: 'You spend more than 90% of income. Even small income '
          'increases or expense cuts can shift you to "saving" territory.',
      severity: 'warning',
    ));
  }
  if (cv > 1.2) {
    tips.add(const Advice(
      headline: 'High variability',
      detail: 'Your daily spending varies a lot. Budgets work better when '
          'you know your typical day. Consider checking the weekly report.',
      severity: 'neutral',
    ));
  }
  if (savingsRate < 0.1 && savingsRate >= 0) {
    tips.add(Advice(
      headline: 'Set a goal',
      detail: monthlyBudget != null
          ? 'Try a savings target of 10% of your income. With a monthly '
          'budget of GH₵${monthlyBudget.toStringAsFixed(0)}, aim for '
          'GH₵${(monthlyBudget * 0.1).toStringAsFixed(0)} saved.'
          : 'Try a savings target of 10% of your income this month.',
      severity: 'neutral',
    ));
  }

  return tips;
}

double _sqrt(double x) {
  if (x <= 0) return 0;
  var guess = x;
  for (var i = 0; i < 20; i++) {
    guess = 0.5 * (guess + x / guess);
  }
  return guess;
}
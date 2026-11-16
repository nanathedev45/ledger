class SavingsContribution {
  final int? id;
  final double amount;
  final DateTime dateTime;
  final String? note;

  const SavingsContribution({
    this.id,
    required this.amount,
    required this.dateTime,
    this.note,
  });
}

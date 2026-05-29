class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });
}
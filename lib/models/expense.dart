class Expense {
  final String id;
  final String title;
  final double amount;
  final String paidBy;
  final List<String> involved;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.involved,
  });

  factory Expense.fromFirestore(Map<String, dynamic> data, String id) {
    return Expense(
      id: id,
      title: data['title'],
      amount: data['amount'],
      paidBy: data['paidBy'],
      involved: List<String>.from(data['involved']),
    );
  }
}

class Expense {
  final int? id;
  final DateTime expenseDate;
  final String category;
  final double amount;
  final String paymentMethod;
  final String? notes;

  Expense({
    this.id,
    required this.expenseDate,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    this.notes,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] != null ? int.parse(map['id'].toString()) : null,
      expenseDate: DateTime.parse(map['expense_date']),
      category: map['category'],
      amount: double.parse(map['amount'].toString()),
      paymentMethod: map['payment_method'],
      notes: map['notes'],
    );
  }
}

class Expense {
  final String id;
  final String title;
  final int amount;
  final String category;
  final DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) {
    int parsedAmount = 0;
    final rawAmount = json['amount'];
    if (rawAmount is int) {
      parsedAmount = rawAmount;
    } else if (rawAmount is num) {
      parsedAmount = rawAmount.toInt();
    } else if (rawAmount is String) {
      parsedAmount = int.tryParse(rawAmount) ?? 0;
    }

    DateTime parsedDate;
    final rawDate = json['date'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return Expense(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      amount: parsedAmount,
      category: json['category']?.toString() ?? 'Lainnya',
      date: parsedDate,
    );
  }
}

class Payment {
  final int? id;
  final double amount;
  final String date;
  final int cardId;
  final int categoryId;
  final bool isRecurring;
  final String? frequency;
  final bool reminderNotification;

  Payment({
    this.id,
    required this.amount,
    required this.date,
    required this.cardId,
    required this.categoryId,
    required this.isRecurring,
    this.frequency,
    required this.reminderNotification,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'date': date,
    'cardId': cardId,
    'categoryId': categoryId,
    'isRecurring': isRecurring ? 1 : 0,
    'frequency': frequency,
    'reminderNotification': reminderNotification ? 1 : 0,
  };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
    id: map['id'],
    amount: map['amount'],
    date: map['date'],
    cardId: map['cardId'],
    categoryId: map['categoryId'],
    isRecurring: map['isRecurring'] == 1,
    frequency: map['frequency'],
    reminderNotification: map['reminderNotification'] == 1,
  );
}
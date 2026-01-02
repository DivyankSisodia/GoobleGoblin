class BankCard {
  final int? id;
  final String bankName;
  final double balance;
  final String date;
  final String type;

  BankCard({this.id, required this.bankName, required this.balance, required this.date, required this.type});

  Map<String, dynamic> toMap() => {'id': id, 'bankName': bankName, 'balance': balance, 'date': date, 'type': type};

  factory BankCard.fromMap(Map<String, dynamic> map) => BankCard(
    id: map['id'],
    bankName: map['bankName'],
    balance: map['balance'],
    date: map['date'],
    type: map['type'],
  );
}
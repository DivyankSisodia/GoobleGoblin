class BankCard {
  final int? id;
  final String bankName;
  final double balance;
  final String date;

  BankCard({this.id, required this.bankName, required this.balance, required this.date});

  Map<String, dynamic> toMap() => {'id': id, 'bankName': bankName, 'balance': balance, 'date': date};

  factory BankCard.fromMap(Map<String, dynamic> map) => BankCard(
    id: map['id'],
    bankName: map['bankName'],
    balance: map['balance'],
    date: map['date'],
  );
}
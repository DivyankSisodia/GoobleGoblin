class BankCard {
  final int? id;
  final String bankName;
  final double balance;
  final String date;
  final String type;
  final bool isSelected;

  BankCard({
    this.id,
    required this.bankName,
    required this.balance,
    required this.date,
    required this.type,
    this.isSelected = false,
  });

  bool get isCredit => type == 'Credit';

  Map<String, dynamic> toMap() => {
        'id': id,
        'bankName': bankName,
        'balance': balance,
        'date': date,
        'type': type,
      };

  factory BankCard.fromMap(Map<String, dynamic> map) => BankCard(
        id: map['id'],
        bankName: map['bankName'],
        balance: (map['balance'] as num).toDouble(),
        date: map['date'],
        type: map['type'],
        isSelected: map['isSelected'] ?? false,
      );

  BankCard copyWith({
    int? id,
    String? bankName,
    double? balance,
    String? date,
    String? type,
    bool? isSelected,
  }) {
    return BankCard(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      balance: balance ?? this.balance,
      date: date ?? this.date,
      type: type ?? this.type,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
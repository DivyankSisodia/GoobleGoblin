class BankCard {
  final int? id;
  final String bankName;
  final double balance;
  final String date;
  final String type;
  final bool isSelected;
  final bool isPrimary;
  final String? createdAt;
  final String? updatedAt;

  BankCard({
    this.id,
    required this.bankName,
    required this.balance,
    required this.date,
    required this.type,
    this.isSelected = false,
    this.isPrimary = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCredit => type == 'Credit';

  Map<String, dynamic> toMap() => {
        'id': id,
        'bankName': bankName,
        'balance': balance,
        'date': date,
        'type': type,
        'isPrimary': isPrimary ? 1 : 0,
        'createdAt': createdAt ?? DateTime.now().toIso8601String(),
        'updatedAt': updatedAt ?? DateTime.now().toIso8601String(),
      };

  factory BankCard.fromMap(Map<String, dynamic> map) => BankCard(
        id: map['id'],
        bankName: map['bankName'],
        balance: (map['balance'] as num).toDouble(),
        date: map['date'],
        type: map['type'],
        isSelected: map['isSelected'] ?? false,
        isPrimary: (map['isPrimary'] as int?) == 1,
        createdAt: map['createdAt'],
        updatedAt: map['updatedAt'],
      );

  BankCard copyWith({
    int? id,
    String? bankName,
    double? balance,
    String? date,
    String? type,
    bool? isSelected,
    bool? isPrimary,
    String? createdAt,
    String? updatedAt,
  }) {
    return BankCard(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      balance: balance ?? this.balance,
      date: date ?? this.date,
      type: type ?? this.type,
      isSelected: isSelected ?? this.isSelected,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
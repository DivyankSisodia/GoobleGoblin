/// Account types for cards/payment sources
enum AccountType {
  cash,
  debit,
  credit;

  String get displayName {
    switch (this) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.debit:
        return 'Debit Card';
      case AccountType.credit:
        return 'Credit Card';
    }
  }

  String get dbValue {
    switch (this) {
      case AccountType.cash:
        return 'CASH';
      case AccountType.debit:
        return 'DEBIT';
      case AccountType.credit:
        return 'CREDIT';
    }
  }

  static AccountType fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'CASH':
        return AccountType.cash;
      case 'CREDIT':
        return AccountType.credit;
      case 'DEBIT':
      default:
        return AccountType.debit;
    }
  }
}

/// Sync status for offline-first architecture
enum SyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete;

  String get dbValue {
    switch (this) {
      case SyncStatus.synced:
        return 'SYNCED';
      case SyncStatus.pendingCreate:
        return 'PENDING_CREATE';
      case SyncStatus.pendingUpdate:
        return 'PENDING_UPDATE';
      case SyncStatus.pendingDelete:
        return 'PENDING_DELETE';
    }
  }

  static SyncStatus fromString(String? value) {
    switch (value) {
      case 'SYNCED':
        return SyncStatus.synced;
      case 'PENDING_CREATE':
        return SyncStatus.pendingCreate;
      case 'PENDING_UPDATE':
        return SyncStatus.pendingUpdate;
      case 'PENDING_DELETE':
        return SyncStatus.pendingDelete;
      default:
        return SyncStatus.pendingCreate;
    }
  }

  bool get isPending => this != SyncStatus.synced;
}

/// Bank Card / Payment Source model
/// Supports Cash, Debit Cards, and Credit Cards
class BankCard {
  final int? id;
  final String bankName;
  final double balance; // For Cash/Debit: actual balance. For Credit: NOT USED
  final String date;
  final String type; // Legacy type field (kept for backwards compatibility)
  final bool isSelected;
  final bool isPrimary;
  final String? createdAt;
  final String? updatedAt;

  // New fields for enhanced card management
  final AccountType accountType;
  final double creditLimit; // Only for Credit Cards
  final double usedAmount; // Only for Credit Cards (amount already spent)

  // Sync fields for offline-first architecture
  final String? uuid;
  final SyncStatus syncStatus;
  final String? lastSyncedAt;
  final bool isDeleted;

  const BankCard({
    this.id,
    required this.bankName,
    required this.balance,
    required this.date,
    required this.type,
    this.isSelected = false,
    this.isPrimary = false,
    this.createdAt,
    this.updatedAt,
    this.accountType = AccountType.debit,
    this.creditLimit = 0,
    this.usedAmount = 0,
    this.uuid,
    this.syncStatus = SyncStatus.pendingCreate,
    this.lastSyncedAt,
    this.isDeleted = false,
  });

  /// For Credit Cards: Available credit = Limit - Used
  double get availableCredit => creditLimit - usedAmount;

  /// For Credit Cards: Usage percentage (0.0 to 1.0)
  double get creditUsagePercentage {
    if (creditLimit <= 0) return 0;
    return (usedAmount / creditLimit).clamp(0.0, 1.0);
  }

  /// Credit usage status for color coding
  CreditUsageStatus get creditUsageStatus {
    final usage = creditUsagePercentage * 100;
    if (usage < 50) return CreditUsageStatus.healthy;
    if (usage < 75) return CreditUsageStatus.warning;
    return CreditUsageStatus.critical;
  }

  /// Display balance based on account type
  double get displayBalance {
    switch (accountType) {
      case AccountType.cash:
      case AccountType.debit:
        return balance;
      case AccountType.credit:
        return availableCredit;
    }
  }

  /// Whether this is a cash account
  bool get isCash => accountType == AccountType.cash;

  /// Whether this is a credit card
  bool get isCredit => accountType == AccountType.credit;

  /// Whether this is a debit card
  bool get isDebit => accountType == AccountType.debit;

  Map<String, dynamic> toMap() => {
    'id': id,
    'bankName': bankName,
    'balance': balance,
    'date': date,
    'type': type,
    'isPrimary': isPrimary ? 1 : 0,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'accountType': accountType.dbValue,
    'creditLimit': creditLimit,
    'usedAmount': usedAmount,
    'uuid': uuid,
    'syncStatus': syncStatus.dbValue,
    'lastSyncedAt': lastSyncedAt,
    'isDeleted': isDeleted ? 1 : 0,
  };

  /// Convert to Supabase-compatible map (remote schema)
  Map<String, dynamic> toSupabaseMap() => {
    'uuid': uuid,
    'bank_name': bankName,
    'balance': balance,
    'date': date,
    'type': type,
    'is_primary': isPrimary,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'account_type': accountType.dbValue,
    'credit_limit': creditLimit,
    'used_amount': usedAmount,
    'is_deleted': isDeleted,
  };

  factory BankCard.fromMap(Map<String, dynamic> map) => BankCard(
    id: map['id'],
    bankName: map['bankName'] ?? '',
    balance: (map['balance'] ?? 0).toDouble(),
    date: map['date'] ?? '',
    type: map['type'] ?? 'Debit',
    isPrimary: (map['isPrimary'] ?? 0) == 1,
    createdAt: map['createdAt'],
    updatedAt: map['updatedAt'],
    accountType: AccountType.fromString(map['accountType']),
    creditLimit: (map['creditLimit'] ?? 0).toDouble(),
    usedAmount: (map['usedAmount'] ?? 0).toDouble(),
    uuid: map['uuid'],
    syncStatus: SyncStatus.fromString(map['syncStatus']),
    lastSyncedAt: map['lastSyncedAt'],
    isDeleted: (map['isDeleted'] ?? 0) == 1,
  );

  /// Create from Supabase row (remote schema uses snake_case)
  factory BankCard.fromSupabaseMap(Map<String, dynamic> map) => BankCard(
    bankName: map['bank_name'] ?? '',
    balance: (map['balance'] ?? 0).toDouble(),
    date: map['date'] ?? '',
    type: map['type'] ?? 'Debit',
    isPrimary: map['is_primary'] == true,
    createdAt: map['created_at'],
    updatedAt: map['updated_at'],
    accountType: AccountType.fromString(map['account_type']),
    creditLimit: (map['credit_limit'] ?? 0).toDouble(),
    usedAmount: (map['used_amount'] ?? 0).toDouble(),
    uuid: map['uuid'],
    syncStatus: SyncStatus.synced,
    lastSyncedAt: DateTime.now().toIso8601String(),
    isDeleted: map['is_deleted'] == true,
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
    AccountType? accountType,
    double? creditLimit,
    double? usedAmount,
    String? uuid,
    SyncStatus? syncStatus,
    String? lastSyncedAt,
    bool? isDeleted,
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
      accountType: accountType ?? this.accountType,
      creditLimit: creditLimit ?? this.creditLimit,
      usedAmount: usedAmount ?? this.usedAmount,
      uuid: uuid ?? this.uuid,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'BankCard(id: $id, bankName: $bankName, accountType: ${accountType.displayName}, '
        'balance: $balance, creditLimit: $creditLimit, usedAmount: $usedAmount)';
  }

  /// Create a Cash account
  factory BankCard.cash({int? id, required double balance}) {
    final now = DateTime.now().toIso8601String();
    return BankCard(
      id: id,
      bankName: 'Cash',
      balance: balance,
      date: now,
      type: 'Cash',
      accountType: AccountType.cash,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a Debit Card account
  factory BankCard.debit({
    int? id,
    required String bankName,
    required double balance,
  }) {
    final now = DateTime.now().toIso8601String();
    return BankCard(
      id: id,
      bankName: bankName,
      balance: balance,
      date: now,
      type: 'Debit',
      accountType: AccountType.debit,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a Credit Card account
  factory BankCard.credit({
    int? id,
    required String bankName,
    required double creditLimit,
    double usedAmount = 0,
  }) {
    final now = DateTime.now().toIso8601String();
    return BankCard(
      id: id,
      bankName: bankName,
      balance: 0, // Not used for credit cards
      date: now,
      type: 'Credit',
      accountType: AccountType.credit,
      creditLimit: creditLimit,
      usedAmount: usedAmount,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Credit usage status for visual indicators
enum CreditUsageStatus {
  healthy, // 0-50% - Green
  warning, // 50-75% - Yellow/Orange
  critical; // 75-100% - Red

  String get label {
    switch (this) {
      case CreditUsageStatus.healthy:
        return 'Healthy';
      case CreditUsageStatus.warning:
        return 'Approaching Limit';
      case CreditUsageStatus.critical:
        return 'Near Limit';
    }
  }
}

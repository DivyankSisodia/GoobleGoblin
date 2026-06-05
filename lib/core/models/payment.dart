import 'card.dart';
import 'category.dart';

class Payment {
  final int? id;
  final double amount;
  final String date;
  final int cardId;
  final int? categoryId;
  final int? subcategoryId;
  final bool isRecurring;
  final String? frequency;
  final bool reminderNotification;
  final String? note;
  final String? createdAt;
  final String? updatedAt;
  
  final Category? category;
  final SubCategory? subcategory;

  // Controls whether this transaction deducts from card balance
  final bool isExternalTransaction;

  // Whether this is incoming money (credit) vs expense (debit)
  final bool isIncome;

  // Sync fields
  final String? uuid;
  final String? cardUuid;
  final String? categoryUuid;
  final String? subcategoryUuid;
  final SyncStatus syncStatus;
  final String? lastSyncedAt;
  final bool isDeleted;

  Payment({
    this.id,
    required this.amount,
    required this.date,
    required this.cardId,
    this.categoryId,
    this.subcategoryId,
    required this.isRecurring,
    this.frequency,
    required this.reminderNotification,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.subcategory,
    this.uuid,
    this.cardUuid,
    this.categoryUuid,
    this.subcategoryUuid,
    this.isExternalTransaction = false,
    this.isIncome = false,
    this.syncStatus = SyncStatus.pendingCreate,
    this.lastSyncedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'date': date,
    'cardId': cardId,
    'categoryId': categoryId,
    'subcategoryId': subcategoryId,
    'isRecurring': isRecurring ? 1 : 0,
    'frequency': frequency,
    'reminderNotification': reminderNotification ? 1 : 0,
    'note': note,
    'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    'uuid': uuid,
    'cardUuid': cardUuid,
    'categoryUuid': categoryUuid,
    'subcategoryUuid': subcategoryUuid,
    'isExternalTransaction': isExternalTransaction ? 1 : 0,
    'isIncome': isIncome ? 1 : 0,
    'syncStatus': syncStatus.dbValue,
    'lastSyncedAt': lastSyncedAt,
    'isDeleted': isDeleted ? 1 : 0,
  };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
    id: map['id'],
    amount: map['amount'],
    date: map['date'],
    cardId: map['cardId'],
    categoryId: map['categoryId'],
    subcategoryId: map['subcategoryId'],
    isRecurring: map['isRecurring'] == 1,
    frequency: map['frequency'],
    reminderNotification: map['reminderNotification'] == 1,
    note: map['note'],
    createdAt: map['createdAt'],
    uuid: map['uuid'],
    cardUuid: map['cardUuid'],
    categoryUuid: map['categoryUuid'],
    subcategoryUuid: map['subcategoryUuid'],
    syncStatus: SyncStatus.fromString(map['syncStatus']),
    lastSyncedAt: map['lastSyncedAt'],
    isExternalTransaction: (map['isExternalTransaction'] ?? 0) == 1,
    isIncome: (map['isIncome'] ?? 0) == 1,
    isDeleted: (map['isDeleted'] ?? 0) == 1,
    category: map['category_label'] != null
        ? Category(
            id: map['categoryId'],
            label: map['category_label'],
            svgIcon: map['category_svgIcon'] ?? '',
          )
        : null,
    subcategory: map['subcategory_label'] != null
        ? SubCategory(
            id: map['subcategoryId'],
            categoryId: map['categoryId'] ?? 0,
            label: map['subcategory_label'],
            svgIcon: map['subcategory_svgIcon'] ?? '',
          )
        : null,
  );

  @override
  String toString() {
    return '''
Payment(
  id: $id,
  amount: $amount,
  date: $date,
  cardId: $cardId,
  categoryId: $categoryId,
  subcategoryId: $subcategoryId,
  isRecurring: $isRecurring,
  note: $note,
  category: $category,
  subcategory: $subcategory,
)
''';
  }

  Payment copyWith({
    int? id,
    double? amount,
    String? date,
    int? cardId,
    int? categoryId,
    int? subcategoryId,
    bool? isRecurring,
    String? frequency,
    bool? reminderNotification,
    String? note,
    String? createdAt,
    String? updatedAt,
    Category? category,
    SubCategory? subcategory,
    bool? isExternalTransaction,
    bool? isIncome,
    String? uuid,
    String? cardUuid,
    String? categoryUuid,
    String? subcategoryUuid,
    SyncStatus? syncStatus,
    String? lastSyncedAt,
    bool? isDeleted,
  }) {
    return Payment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      cardId: cardId ?? this.cardId,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      isRecurring: isRecurring ?? this.isRecurring,
      frequency: frequency ?? this.frequency,
      reminderNotification: reminderNotification ?? this.reminderNotification,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      isExternalTransaction: isExternalTransaction ?? this.isExternalTransaction,
      isIncome: isIncome ?? this.isIncome,
      uuid: uuid ?? this.uuid,
      cardUuid: cardUuid ?? this.cardUuid,
      categoryUuid: categoryUuid ?? this.categoryUuid,
      subcategoryUuid: subcategoryUuid ?? this.subcategoryUuid,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

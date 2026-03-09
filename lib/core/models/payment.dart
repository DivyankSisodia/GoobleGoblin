import 'card.dart';
import 'category.dart';

class Payment {
  final int? id;
  final double amount;
  final String date;
  final int cardId;
  final int categoryId;
  final bool isRecurring;
  final String? frequency;
  final bool reminderNotification;
  final String? note;
  final String? createdAt;
  final String? updatedAt;
  final Category? category;

  // Sync fields
  final String? uuid;
  final String? cardUuid;
  final String? categoryUuid;
  final SyncStatus syncStatus;
  final String? lastSyncedAt;
  final bool isDeleted;

  Payment({
    this.id,
    required this.amount,
    required this.date,
    required this.cardId,
    required this.categoryId,
    required this.isRecurring,
    this.frequency,
    required this.reminderNotification,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.uuid,
    this.cardUuid,
    this.categoryUuid,
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
    'isRecurring': isRecurring ? 1 : 0,
    'frequency': frequency,
    'reminderNotification': reminderNotification ? 1 : 0,
    'note': note,
    'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    'uuid': uuid,
    'cardUuid': cardUuid,
    'categoryUuid': categoryUuid,
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
    isRecurring: map['isRecurring'] == 1,
    frequency: map['frequency'],
    reminderNotification: map['reminderNotification'] == 1,
    note: map['note'],
    createdAt: map['createdAt'],
    uuid: map['uuid'],
    cardUuid: map['cardUuid'],
    categoryUuid: map['categoryUuid'],
    syncStatus: SyncStatus.fromString(map['syncStatus']),
    lastSyncedAt: map['lastSyncedAt'],
    isDeleted: (map['isDeleted'] ?? 0) == 1,
    category: map['category_label'] != null
        ? Category(
            id: map['categoryId'],
            label: map['category_label'],
            icon: map['category_icon'],
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
  isRecurring: $isRecurring,
  frequency: $frequency,
  reminderNotification: $reminderNotification,
  note: $note,
  createdAt: $createdAt,
  category: $category,
)
''';
  }
}

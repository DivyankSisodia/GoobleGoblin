import 'card.dart' show SyncStatus;

class WishlistItem {
  final int? id;
  final String url;
  final String? title;
  final String? imageUrl;
  final double? price;
  final String? notes;
  final String dateAdded;
  final bool isPurchased;
  final String? updatedAt;

  // Sync fields
  final String? uuid;
  final SyncStatus syncStatus;
  final String? lastSyncedAt;
  final bool isDeleted;

  WishlistItem({
    this.id,
    required this.url,
    this.title,
    this.imageUrl,
    this.price,
    this.notes,
    required this.dateAdded,
    this.isPurchased = false,
    this.updatedAt,
    this.uuid,
    this.syncStatus = SyncStatus.pendingCreate,
    this.lastSyncedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'url': url,
    'title': title,
    'image_url': imageUrl,
    'price': price,
    'notes': notes,
    'date_added': dateAdded,
    'is_purchased': isPurchased ? 1 : 0,
    'updated_at': updatedAt,
    'uuid': uuid,
    'syncStatus': syncStatus.dbValue,
    'lastSyncedAt': lastSyncedAt,
    'isDeleted': isDeleted ? 1 : 0,
  };

  /// Convert to Supabase-compatible map
  Map<String, dynamic> toSupabaseMap() => {
    'uuid': uuid,
    'url': url,
    'title': title,
    'image_url': imageUrl,
    'price': price,
    'notes': notes,
    'date_added': dateAdded,
    'is_purchased': isPurchased,
    'updated_at': updatedAt,
    'is_deleted': isDeleted,
  };

  factory WishlistItem.fromMap(Map<String, dynamic> map) => WishlistItem(
    id: map['id'],
    url: map['url'],
    title: map['title'],
    imageUrl: map['image_url'],
    price: map['price'],
    notes: map['notes'],
    dateAdded: map['date_added'],
    isPurchased: map['is_purchased'] == 1,
    updatedAt: map['updated_at'],
    uuid: map['uuid'],
    syncStatus: SyncStatus.fromString(map['syncStatus']),
    lastSyncedAt: map['lastSyncedAt'],
    isDeleted: (map['isDeleted'] ?? 0) == 1,
  );

  /// Create from Supabase row
  factory WishlistItem.fromSupabaseMap(Map<String, dynamic> map) =>
      WishlistItem(
        url: map['url'] ?? '',
        title: map['title'],
        imageUrl: map['image_url'],
        price: (map['price'] as num?)?.toDouble(),
        notes: map['notes'],
        dateAdded: map['date_added'] ?? '',
        isPurchased: map['is_purchased'] == true,
        updatedAt: map['updated_at'],
        uuid: map['uuid'],
        syncStatus: SyncStatus.synced,
        lastSyncedAt: DateTime.now().toIso8601String(),
        isDeleted: map['is_deleted'] == true,
      );

  WishlistItem copyWith({
    int? id,
    String? url,
    String? title,
    String? imageUrl,
    double? price,
    String? notes,
    String? dateAdded,
    bool? isPurchased,
    String? updatedAt,
    String? uuid,
    SyncStatus? syncStatus,
    String? lastSyncedAt,
    bool? isDeleted,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      dateAdded: dateAdded ?? this.dateAdded,
      isPurchased: isPurchased ?? this.isPurchased,
      updatedAt: updatedAt ?? this.updatedAt,
      uuid: uuid ?? this.uuid,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

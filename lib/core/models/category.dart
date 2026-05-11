import 'package:flutter/material.dart';
import '../app_images.dart';
import 'card.dart' show SyncStatus;

/// Category model for transaction categorization
/// All categories are predefined - users cannot create custom categories
class Category {
  final int? id;
  final String label;
  final String icon; // Icon name (legacy)
  final String? assetPath; // Path to image asset
  final bool isPredefined;
  final Color? color; // Optional color for the category

  // Sync fields
  final String? uuid;
  final SyncStatus syncStatus;
  final String? lastSyncedAt;
  final bool isDeleted;

  const Category({
    this.id,
    required this.label,
    required this.icon,
    this.assetPath,
    this.isPredefined = true,
    this.color,
    this.uuid,
    this.syncStatus = SyncStatus.pendingCreate,
    this.lastSyncedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'icon': icon,
    'assetPath': assetPath,
    'isPredefined': isPredefined ? 1 : 0,
    'uuid': uuid,
    'syncStatus': syncStatus.dbValue,
    'lastSyncedAt': lastSyncedAt,
    'isDeleted': isDeleted ? 1 : 0,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'],
    label: map['label'] ?? '',
    icon: map['icon'] ?? '',
    assetPath: map['assetPath'],
    isPredefined: (map['isPredefined'] ?? 1) == 1,
    uuid: map['uuid'],
    syncStatus: SyncStatus.fromString(map['syncStatus']),
    lastSyncedAt: map['lastSyncedAt'],
    isDeleted: (map['isDeleted'] ?? 0) == 1,
  );

  Category copyWith({
    int? id,
    String? label,
    String? icon,
    String? assetPath,
    bool? isPredefined,
    Color? color,
    String? uuid,
    SyncStatus? syncStatus,
    String? lastSyncedAt,
    bool? isDeleted,
  }) {
    return Category(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      assetPath: assetPath ?? this.assetPath,
      isPredefined: isPredefined ?? this.isPredefined,
      color: color ?? this.color,
      uuid: uuid ?? this.uuid,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, label: $label, icon: $icon)';
  }

  /// Check if category has an image asset
  bool get hasAsset => assetPath != null && assetPath!.isNotEmpty;
}

/// Predefined categories with image assets
class PredefinedCategories {
  PredefinedCategories._();

  static const List<Category> all = [
    // Subscriptions & Entertainment
    Category(
      label: 'Netflix',
      icon: 'netflix',
      assetPath: AppImages.netflix,
      color: Color(0xFFE50914),
    ),
    Category(
      label: 'YouTube',
      icon: 'youtube',
      assetPath: AppImages.youtube,
      color: Color(0xFFFF0000),
    ),
    Category(
      label: 'Amazon',
      icon: 'amazon',
      assetPath: AppImages.amazon,
      color: Color(0xFFFF9900),
    ),

    // Food & Delivery
    Category(
      label: 'Zomato',
      icon: 'zomato',
      assetPath: AppImages.zomato,
      color: Color(0xFFE23744),
    ),
    Category(
      label: 'Swiggy',
      icon: 'swiggy',
      assetPath: AppImages.swiggy,
      color: Color(0xFFFC8019),
    ),
    Category(
      label: 'Food & Dining',
      icon: 'food',
      assetPath: AppImages.food,
      color: Color(0xFFFF6B6B),
    ),

    // Shopping
    Category(
      label: 'Shopping',
      icon: 'shopping',
      assetPath: AppImages.bagShopping,
      color: Color(0xFF9B59B6),
    ),
    Category(
      label: 'Grocery',
      icon: 'grocery',
      assetPath: AppImages.grocery,
      color: Color(0xFF27AE60),
    ),

    // Transportation
    Category(
      label: 'Transport',
      icon: 'transport',
      assetPath: AppImages.bike,
      color: Color(0xFF3498DB),
    ),

    // Bills & Utilities
    Category(
      label: 'Mobile Recharge',
      icon: 'mobile',
      assetPath: AppImages.mobile,
      color: Color(0xFF2ECC71),
    ),
    Category(
      label: 'Utilities',
      icon: 'utilities',
      assetPath: AppImages.utils,
      color: Color(0xFF1ABC9C),
    ),
    Category(
      label: 'Rent',
      icon: 'rent',
      assetPath: AppImages.rent,
      color: Color(0xFFE74C3C),
    ),

    // Cash & Misc
    Category(
      label: 'Cash Withdrawal',
      icon: 'cash',
      assetPath: AppImages.cash,
      color: Color(0xFF27AE60),
    ),
  ];

  /// Get category by label
  static Category? getByLabel(String label) {
    try {
      return all.firstWhere(
        (c) => c.label.toLowerCase() == label.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get category by icon name
  static Category? getByIcon(String iconName) {
    try {
      return all.firstWhere(
        (c) => c.icon.toLowerCase() == iconName.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get color for category
  static Color getColor(
    String? iconName, {
    Color defaultColor = const Color(0xFF95A5A6),
  }) {
    if (iconName == null) return defaultColor;
    final category = getByIcon(iconName);
    return category?.color ?? defaultColor;
  }

  /// Get asset path for category
  static String? getAssetPath(String? iconName) {
    if (iconName == null) return null;
    final category = getByIcon(iconName);
    return category?.assetPath;
  }
}

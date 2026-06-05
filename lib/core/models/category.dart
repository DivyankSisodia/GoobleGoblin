import 'package:flutter/material.dart';
import '../app_images.dart';
import 'card.dart' show SyncStatus;

/// Category model for transaction categorization
/// All categories are predefined - users cannot create custom categories
class Category {
  final int? id;
  final String label;
  final String icon; // Icon name (legacy / template identifier)
  final String? assetPath; // Path to image asset
  final String? customSvg; // Inline SVG markup for custom icon
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
    this.customSvg,
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
    'customSvg': customSvg,
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
    customSvg: map['customSvg'],
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
    String? customSvg,
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
      customSvg: customSvg ?? this.customSvg,
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

  /// Check if category has custom inline SVG
  bool get hasCustomSvg => customSvg != null && customSvg!.trim().isNotEmpty;

  /// Whether this category uses SVG (either inline or asset)
  bool get usesSvgIcon =>
      hasCustomSvg || (hasAsset && assetPath!.toLowerCase().endsWith('.svg'));
}

/// Predefined categories with image assets
class PredefinedCategories {
  PredefinedCategories._();

  static const List<Category> all = [
    // Broad spending groups. Merchants/apps are captured from transaction notes.
    Category(
      label: 'Shopping',
      icon: 'shopping',
      assetPath: AppImages.shopping,
      color: Color(0xFF9B59B6),
    ),
    Category(
      label: 'Grocery',
      icon: 'grocery',
      assetPath: AppImages.grocery,
      color: Color(0xFF27AE60),
    ),
    Category(
      label: 'Home Utils',
      icon: 'home_utils',
      assetPath: AppImages.homeUtils,
      color: Color(0xFF1ABC9C),
    ),
    Category(
      label: 'Subscriptions',
      icon: 'subscriptions',
      assetPath: AppImages.subscriptions,
      color: Color(0xFFE50914),
    ),
    Category(
      label: 'Bike',
      icon: 'bike',
      assetPath: AppImages.bike,
      color: Color(0xFF3498DB),
    ),
    Category(
      label: 'Food & Dining',
      icon: 'food',
      assetPath: AppImages.foodDining,
      color: Color(0xFFFF6B6B),
    ),
    Category(label: 'Income', icon: 'income', color: Color(0xFF4CAF50)),
  ];

  static const Map<String, String> legacyLabelRemap = {
    'netflix': 'Subscriptions',
    'youtube': 'Subscriptions',
    'entertainment': 'Subscriptions',
    'amazon': 'Shopping',
    'personal care': 'Shopping',
    'others': 'Shopping',
    'zomato': 'Food & Dining',
    'swiggy': 'Food & Dining',
    'transport': 'Bike',
    'transportation': 'Bike',
    'travel': 'Bike',
    'utilities': 'Home Utils',
    'bills & utilities': 'Home Utils',
    'mobile recharge': 'Home Utils',
    'rent': 'Home Utils',
    'cash withdrawal': 'Home Utils',
    'health & fitness': 'Home Utils',
    'education': 'Home Utils',
  };

  /// Merchant/service keywords used to deep-dive transactions from notes.
  static const List<String> transactionNoteKeywords = [
    'amazon',
    'flipkart',
    'myntra',
    'ajio',
    'meesho',
    'nykaa',
    'tata cliq',
    'snapdeal',
    'shopclues',
    'firstcry',
    'blinkit',
    'zepto',
    'bigbasket',
    'dmart',
    'jiomart',
    'reliance fresh',
    'swiggy',
    'zomato',
    'dominos',
    'pizza hut',
    'mcdonalds',
    'kfc',
    'starbucks',
    'barbeque nation',
    'uber',
    'ola',
    'rapido',
    'indigo',
    'irctc',
    'makemytrip',
    'netflix',
    'youtube',
    'spotify',
    'hotstar',
    'prime video',
    'sony liv',
    'jio',
    'airtel',
    'vodafone',
    'electricity',
    'water bill',
    'gas bill',
    'rent',
    'maintenance',
    'urban company',
    'apollo',
    'medplus',
    'pharmeasy',
    'bookmyshow',
    'cred',
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

  static String? legacyTargetLabel(String? label) {
    final normalized = (label ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final category in all) {
      if (category.label.toLowerCase() == normalized) return category.label;
    }

    return legacyLabelRemap[normalized];
  }

  static bool isSystemManagedLabel(String? label) {
    return legacyTargetLabel(label) != null;
  }
}

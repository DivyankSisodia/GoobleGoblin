import 'package:flutter/material.dart';
import 'card.dart' show SyncStatus;
import '../constants/app_icons.dart';

/// SubCategory model
class SubCategory {
  final int? id;
  final int categoryId;
  final String label;
  final String svgIcon;

  // Sync fields
  final String? uuid;
  final String? categoryUuid;
  final SyncStatus syncStatus;
  final String? lastSyncedAt;
  final bool isDeleted;

  const SubCategory({
    this.id,
    required this.categoryId,
    required this.label,
    required this.svgIcon,
    this.uuid,
    this.categoryUuid,
    this.syncStatus = SyncStatus.pendingCreate,
    this.lastSyncedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'categoryId': categoryId,
    'label': label,
    'svgIcon': svgIcon,
    'uuid': uuid,
    'categoryUuid': categoryUuid,
    'syncStatus': syncStatus.dbValue,
    'lastSyncedAt': lastSyncedAt,
    'isDeleted': isDeleted ? 1 : 0,
  };

  factory SubCategory.fromMap(Map<String, dynamic> map) => SubCategory(
    id: map['id'],
    categoryId: map['categoryId'] ?? 0,
    label: map['label'] ?? '',
    svgIcon: map['svgIcon'] ?? AppIcons.placeholderSvg,
    uuid: map['uuid'],
    categoryUuid: map['categoryUuid'],
    syncStatus: SyncStatus.fromString(map['syncStatus']),
    lastSyncedAt: map['lastSyncedAt'],
    isDeleted: (map['isDeleted'] ?? 0) == 1,
  );

  SubCategory copyWith({
    int? id,
    int? categoryId,
    String? label,
    String? svgIcon,
    String? uuid,
    String? categoryUuid,
    SyncStatus? syncStatus,
    String? lastSyncedAt,
    bool? isDeleted,
  }) {
    return SubCategory(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      label: label ?? this.label,
      svgIcon: svgIcon ?? this.svgIcon,
      uuid: uuid ?? this.uuid,
      categoryUuid: categoryUuid ?? this.categoryUuid,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

/// Category model for transaction categorization
class Category {
  final int? id;
  final String label;
  final String svgIcon;
  final Color? color;
  final List<SubCategory> subcategories;

  // Sync fields
  final String? uuid;
  final SyncStatus syncStatus;
  final String? lastSyncedAt;
  final bool isDeleted;

  const Category({
    this.id,
    required this.label,
    required this.svgIcon,
    this.color,
    this.subcategories = const [],
    this.uuid,
    this.syncStatus = SyncStatus.pendingCreate,
    this.lastSyncedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'svgIcon': svgIcon,
    'uuid': uuid,
    'syncStatus': syncStatus.dbValue,
    'lastSyncedAt': lastSyncedAt,
    'isDeleted': isDeleted ? 1 : 0,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'],
    label: map['label'] ?? '',
    svgIcon: map['svgIcon'] ?? AppIcons.placeholderSvg,
    uuid: map['uuid'],
    syncStatus: SyncStatus.fromString(map['syncStatus']),
    lastSyncedAt: map['lastSyncedAt'],
    isDeleted: (map['isDeleted'] ?? 0) == 1,
    subcategories: map['subcategories'] != null 
        ? List<SubCategory>.from(map['subcategories'].map((x) => SubCategory.fromMap(x))) 
        : const [],
  );

  Category copyWith({
    int? id,
    String? label,
    String? svgIcon,
    Color? color,
    List<SubCategory>? subcategories,
    String? uuid,
    SyncStatus? syncStatus,
    String? lastSyncedAt,
    bool? isDeleted,
  }) {
    return Category(
      id: id ?? this.id,
      label: label ?? this.label,
      svgIcon: svgIcon ?? this.svgIcon,
      color: color ?? this.color,
      subcategories: subcategories ?? this.subcategories,
      uuid: uuid ?? this.uuid,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, label: $label, subcategories: \${subcategories.length})';
  }
}

/// Predefined seed data
class DefaultCategories {
  static const List<Category> all = [
    Category(
      label: 'Food & Grocery',
      svgIcon: AppIcons.foodAndGrocery,
      color: Color(0xFFFF6B6B),
      subcategories: [
        SubCategory(categoryId: 0, label: 'Zomato', svgIcon: AppIcons.zomato),
        SubCategory(categoryId: 0, label: 'Swiggy', svgIcon: AppIcons.swiggy),
        SubCategory(categoryId: 0, label: 'Amazon', svgIcon: AppIcons.amazon),
        SubCategory(categoryId: 0, label: 'Zepto', svgIcon: AppIcons.zepto),
        SubCategory(categoryId: 0, label: 'Essentials', svgIcon: AppIcons.essentials),
        SubCategory(categoryId: 0, label: 'Tiffin', svgIcon: AppIcons.tiffin),
        SubCategory(categoryId: 0, label: 'Party', svgIcon: AppIcons.party),
        SubCategory(categoryId: 0, label: 'Flipkart', svgIcon: AppIcons.flipkart),
      ]
    ),
    Category(
      label: 'Bills',
      svgIcon: AppIcons.bills,
      color: Color(0xFF1ABC9C),
      subcategories: [
        SubCategory(categoryId: 0, label: 'Rent', svgIcon: AppIcons.rent),
        SubCategory(categoryId: 0, label: 'Electricity', svgIcon: AppIcons.electricity),
        SubCategory(categoryId: 0, label: 'Loan', svgIcon: AppIcons.loan),
      ]
    ),
    Category(
      label: 'Subscriptions',
      svgIcon: AppIcons.subscriptions,
      color: Color(0xFFE50914),
      subcategories: [
        SubCategory(categoryId: 0, label: 'Mobile', svgIcon: AppIcons.mobile),
        SubCategory(categoryId: 0, label: 'WiFi', svgIcon: AppIcons.wifi),
        SubCategory(categoryId: 0, label: 'Netflix', svgIcon: AppIcons.netflix),
        SubCategory(categoryId: 0, label: 'Spotify', svgIcon: AppIcons.spotify),
        SubCategory(categoryId: 0, label: 'Llm', svgIcon: AppIcons.llm),
      ]
    ),
    Category(
      label: 'Bike',
      svgIcon: AppIcons.bike,
      color: Color(0xFF3498DB),
    ),
    Category(
      label: 'Shopping',
      svgIcon: AppIcons.shopping,
      color: Color(0xFF9B59B6),
      subcategories: [
        SubCategory(categoryId: 0, label: 'Amazon', svgIcon: AppIcons.amazon),
        SubCategory(categoryId: 0, label: 'Flipkart', svgIcon: AppIcons.flipkart),
      ]
    ),
    Category(
      label: 'Miscellaneous',
      svgIcon: AppIcons.miscellaneous,
      color: Color(0xFF95A5A6),
      subcategories: [
        SubCategory(categoryId: 0, label: 'Loan', svgIcon: AppIcons.loan),
        SubCategory(categoryId: 0, label: 'Money Transfer', svgIcon: AppIcons.moneyTransfer),
      ]
    ),
  ];

  static const List<String> transactionNoteKeywords = [
    'amazon', 'flipkart', 'swiggy', 'zomato', 'uber', 'ola', 'netflix', 'spotify',
    'zepto', 'cred', 'github', 'furlenco', 'icici', 'hdfc', 'paytm', 'phonepe',
    'gpay', 'google', 'electricity', 'rent', 'loan', 'emi', 'salary',
  ];
}

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
    );
  }
}

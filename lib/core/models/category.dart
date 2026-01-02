class Category {
  final int? id;
  final String label;
  final String icon; // Store icon as a String (e.g., 'home', 'food')

  Category({this.id, required this.label, required this.icon});

  Map<String, dynamic> toMap() => {'id': id, 'label': label, 'icon': icon};

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'],
    label: map['label'],
    icon: map['icon'],
  );
}
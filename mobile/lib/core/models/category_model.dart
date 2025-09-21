class Category {
  final String id;
  final String name;
  final String nameSomali;
  final String? description;
  final String? descriptionSomali;

  final String color;
  final String icon;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  final int bookCount;

  Category({
    required this.id,
    required this.name,
    required this.nameSomali,
    this.description,
    this.descriptionSomali,
    this.color = '#1E3A8A',
    this.icon = 'book',
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.bookCount = 0,
  });

  // Factory constructor from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameSomali: json['name_somali'] ?? json['nameSomali'] ?? '',
      description: json['description'],
      descriptionSomali: json['description_somali'] ?? json['descriptionSomali'],
      color: json['color'] ?? '#1E3A8A',
      icon: json['icon'] ?? 'book',
      isActive: json['is_active'] == true || json['isActive'] == true || json['is_active'] == 1 || json['isActive'] == 1,
      sortOrder: json['sort_order'] ?? json['sortOrder'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : json['updatedAt'] != null 
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
      bookCount: json['book_count'] ?? json['bookCount'] ?? 0,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_somali': nameSomali,
      'description': description,
      'description_somali': descriptionSomali,
      'color': color,
      'icon': icon,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'book_count': bookCount,
    };
  }

  // Copy with method
  Category copyWith({
    String? id,
    String? name,
    String? nameSomali,
    String? description,
    String? descriptionSomali,
    String? color,
    String? icon,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? bookCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      nameSomali: nameSomali ?? this.nameSomali,
      description: description ?? this.description,
      descriptionSomali: descriptionSomali ?? this.descriptionSomali,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookCount: bookCount ?? this.bookCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category{id: $id, name: $name, isActive: $isActive}';
  }
}

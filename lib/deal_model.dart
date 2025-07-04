
/// model of the deal to fetch from supabase  
class Deal {
  final int id;
  final String name;
  final String description;
  final String? image;

  Deal({
    required this.id,
    required this.name,
    required this.description,
    this.image,
  });
  // Factory constructor to create Deal from JSON
  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      image: json['image'] as String?,
    );
  }

  // Convert Deal to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
    };
  }

  // Create a copy of Deal with updated values
  Deal copyWith({
    int? id,
    String? name,
    String? description,
    String? image,
  }) {
    return Deal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
    );
  }

  @override
  String toString() {
    return 'Deal{id: $id, name: $name, description: $description, image: $image}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Deal &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.image == image;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        (image?.hashCode ?? 0);
  }
}
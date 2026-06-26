class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.photoPath,
  });

  final String id;
  final String name;
  final String relationship;
  final String? photoPath;

  FamilyMember copyWith({
    String? id,
    String? name,
    String? relationship,
    String? photoPath,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      if (photoPath != null) 'photoPath': photoPath,
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      photoPath: json['photoPath'] as String?,
    );
  }
}

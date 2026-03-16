class FamilyMember {
  final String id;
  final String name;
  final int age;
  final String relation;
  final String? uid; // Unique identifier like Aadhar
  final DateTime createdAt;

  FamilyMember({
    required this.id,
    required this.name,
    required this.age,
    required this.relation,
    this.uid,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  FamilyMember copyWith({
    String? id,
    String? name,
    int? age,
    String? relation,
    String? uid,
    DateTime? createdAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      relation: relation ?? this.relation,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'relation': relation,
      'uid': uid,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      relation: json['relation'] ?? '',
      uid: json['uid'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  @override
  String toString() =>
      'FamilyMember(id: $id, name: $name, age: $age, relation: $relation, uid: $uid)';
}

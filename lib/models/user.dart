class PosUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'owner' or 'cashier'
  final String? branchId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PosUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'cashier',
    this.branchId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'branch_id': branchId,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory PosUser.fromJson(Map<String, dynamic> json) => PosUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        role: json['role'] as String? ?? 'cashier',
        branchId: json['branch_id'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );

  PosUser copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? branchId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PosUser(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name ?? this.name,
        role: role ?? this.role,
        branchId: branchId ?? this.branchId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

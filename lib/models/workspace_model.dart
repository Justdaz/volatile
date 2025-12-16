import 'package:vasvault/models/workspace_member_model.dart';

class Workspace {
  final int id;
  final String name;
  final String description;
  final int ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WorkspaceMember> members;

  Workspace({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.members = const [],
  });

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Untitled',
      description: json['description'] ?? '',
      ownerId: json['owner_id'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      members:
          (json['members'] as List<dynamic>?)
              ?.map((e) => WorkspaceMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'members': members
          .map((m) => {'user_id': m.id, 'email': m.email, 'role': m.role})
          .toList(),
    };
  }
}

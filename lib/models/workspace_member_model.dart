class WorkspaceMember {
  final int id;
  final String email;
  final String role;

  WorkspaceMember({
    required this.id,
    required this.email,
    required this.role,
  });

  factory WorkspaceMember.fromJson(Map<String, dynamic> json) {
    return WorkspaceMember(
      id: json['user_id'] ?? json['id'] ?? 0,
      email: json['user']?['email'] ?? json['email'] ?? 'Unknown User',
      role: json['role'] ?? 'viewer',
    );
  }
}
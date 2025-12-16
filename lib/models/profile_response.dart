class ProfileResponse {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String? profilePicture;
  final DateTime? createdAt;

  ProfileResponse({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    this.profilePicture,
    this.createdAt,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ProfileResponse(
      id: data['id'] as int? ?? 0,
      username: data['username'] as String? ?? '',
      fullName:
          (data['fullName'] as String?) ??
          (data['full_name'] as String?) ??
          (data['username'] as String?) ??
          '',
      email: data['email'] as String? ?? '',
      profilePicture:
          (data['profilePicture'] as String?) ??
          (data['profile_picture'] as String?),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'] as String)
          : (data['createdAt'] != null
                ? DateTime.tryParse(data['createdAt'] as String)
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'profile_picture': profilePicture,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

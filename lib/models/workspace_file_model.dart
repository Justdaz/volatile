import 'package:vasvault/constants/app_constant.dart';

class WorkspaceFile {
  final int id;
  final String fileName;
  final String fileUrl;
  final int size;
  final String mimeType;
  final DateTime createdAt;

  WorkspaceFile({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.size,
    required this.mimeType,
    required this.createdAt,
  });

  factory WorkspaceFile.fromJson(Map<String, dynamic> json) {
    return WorkspaceFile(
      id: json['id'] ?? 0,

      fileName: json['file_name'] ?? json['filename'] ?? 'Tanpa Nama',

      fileUrl: json['file_path'] ?? json['file_url'] ?? '',

      size: json['size'] ?? 0,
      mimeType: json['mime_type'] ?? 'unknown',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  String get fullDownloadUrl {
    final baseUrl = AppConstants.baseUrl;

    if (fileUrl.startsWith('http')) return fileUrl;
    return '$baseUrl/$fileUrl';
  }
}